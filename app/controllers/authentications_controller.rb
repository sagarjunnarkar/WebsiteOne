class AuthenticationsController < ApplicationController
  before_action :authenticate_user!, only: [:destroy]

  def create
    if request.env['omniauth.params']['youtube']
      link_to_youtube and return
    end

    omniauth = request.env['omniauth.auth']
    authentication = Authentication.find_by_provider_and_uid(omniauth['provider'], omniauth['uid'])

    @path = request.env['omniauth.origin'] || root_path

    if authentication.present?
      attempt_login_with_auth(authentication, @path)

    elsif current_user
      create_new_authentication_for_current_user(omniauth, @path)

    else
      create_new_user_with_authentication(omniauth)
    end
  end

  def failure
    # Bryan: TESTED
    flash[:alert] = 'Authentication failed.'
    redirect_to root_path
  end

  def destroy
    if params[:id]=='youtube'
      unlink_from_youtube and return
    end

    @authentication = current_user.authentications.find(params[:id])
    if @authentication
      if current_user.authentications.count == 1 and current_user.encrypted_password.blank?
        # Bryan: TESTED
        flash[:alert] = 'Bad idea!'
      elsif @authentication.destroy
        flash[:notice] = 'Successfully removed profile.'
      else
        # Bryan: useful logging in case some unexpected error occurs
        Rails.logger.error @authentication.errors.full_messages
        flash[:alert] = 'Authentication method could not be removed.'
      end
    else
      flash[:alert] = 'Authentication method not found.'
    end
    redirect_to edit_user_registration_path(current_user)
  end


  private

  def link_to_youtube
    user = current_user
    if (token = request.env['omniauth.auth']['credentials']['token']) && !user.youtube_id
      user.youtube_id = Youtube.channel_id(token)
      user.save
    end

    redirect_to(request.env['omniauth.origin'] || root_path)
  end

  def unlink_from_youtube
    current_user.youtube_id = nil
    current_user.save

    redirect_to(params[:origin] || root_path)
  end

  def attempt_login_with_auth(authentication, path)
    if current_user.present? and authentication.user != current_user
      flash[:alert] = 'Another account is already associated with these credentials!'
      redirect_to path
    else
      flash[:notice] = 'Signed in successfully.'
      sign_in_and_redirect(:user, authentication.user)
    end
  end

  def create_new_authentication_for_current_user(omniauth, path)
    if auth = current_user.authentications.build(:provider => omniauth['provider'], :uid => omniauth['uid'])
      if auth.save
        # Bryan: TESTED
        flash[:notice] = 'Authentication successful.'
        redirect_to path
      else
        # Bryan: TESTED
        flash[:alert] = 'Unable to create additional profiles.'
        redirect_to @path
      end
    end
  end

  def create_new_user_with_authentication(omniauth)
    user = User.new
    user.apply_omniauth(omniauth)

    if user.save
      # Bryan: TESTED
      Mailer.send_welcome_message(user).deliver
      flash[:notice] = 'Signed in successfully.'
      sign_in_and_redirect(:user, user)
    else
      # Bryan: TESTED
      session[:omniauth] = omniauth.except('extra')
      redirect_to new_user_registration_url
    end
  end
end












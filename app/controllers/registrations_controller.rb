class RegistrationsController < Devise::RegistrationsController
  def create
    super
    session[:omniauth] = nil unless @user.new_record?
    Mailer.send_welcome_message(@user).deliver unless @user.invalid?

  end

  def update
    # raise 'sf'
    if params[:preview]
      params[:user][:display_email] == '1' ? display_email = true : display_email = false
      resource.display_email = display_email
      render :action => 'edit'
    else
      skills = params[:user].delete "skill_list"
      account_update_params = devise_parameter_sanitizer.sanitize(:account_update)

      if account_update_params[:password].blank?
        account_update_params.delete('password')
        account_update_params.delete('password_confirmation')
      end

      # Bryan: creates a new but identical object
      @user = User.friendly.find(current_user.friendly_id)
      @user.skill_list = skills
      if @user.update_attributes(account_update_params)
        set_flash_message :notice, :updated
        # Sign in the user bypassing validation in case his password changed
        sign_in current_user, :bypass => true
        redirect_to after_update_path_for(@user)
      else
        puts @user.inspect
        puts @user.errors.full_message.join(', ')
        render :edit
      end
    end
  end

  def preview
    @user = current_user
  end


  private

  def build_resource(*args)
    super
    if session[:omniauth]
      @user.apply_omniauth(session[:omniauth])
      @user.valid?
    end
  end
end
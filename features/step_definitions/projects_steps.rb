Then(/^I should see "([^"]*)" table$/) do |legend|
  page.should have_css 'h1', text: legend
end

When(/^I should see column "([^"]*)"$/) do |column|
  within('table#projects thead') do
    page.should have_css('th', :text => column)
  end
end

When(/^There are projects in the database$/) do
  Project.create(title: "Title 1", description: "Description 1", status: "Status 1")
  Project.create(title: "Title 2", description: "Description 2", status: "Status 2")
end

Given(/^the following projects exist:$/) do |table|
  #TODO YA rewrite with factoryGirl
  temp_author = nil
  table.hashes.each do |hash|
    if hash[:author].present?
      u = User.find_by_first_name hash[:author]
      project = u.projects.create(hash.except('author', 'tags'))
    else
      if temp_author.nil?
        temp_author = User.create first_name: 'First',
                                  last_name: 'Last',
                                  email: "dummy#{User.count}@users.co",
                                  password: '1234124124'
      end
      project = temp_author.projects.create(hash.except('author', 'tags'))
    end
    if hash[:tags]
      project.tag_list.add(hash[:tags], parse: true)
      project.save
    end
  end
end

Then /^I should see a form for "([^"]*)"$/ do |form_purpose|
  case form_purpose
    when 'creating a new project'
      page.should have_text form_purpose
      page.should have_css('form#new_project')
  end
end

When(/^I click the "([^"]*)" button for project "([^"]*)"$/) do |button, project_name|
  project = Project.find_by_title(project_name)
  if project
    within("tr##{project.id}") do
      click_link_or_button button
    end
  else
    visit path_to(button, 'non-existent')
  end
end

Given(/^the document "([^"]*)" has a child document with title "([^"]*)"$/) do |parent, child|
  parent_doc = Document.find_by_title(parent)
  parent_doc.children.create!(
      {
          :project_id => parent_doc.project_id,
          :title => child,
          user_id: parent_doc.user_id
      }
  )
end

Then(/^I should become a member of project "([^"]*)"$/) do | name|
  object = Project.find_by_title(name)
  @user.follow(object)
end

When(/^I am a member of project "([^"]*)"$/) do |name|
  step %Q{I should become a member of project "#{name}"}
end
Then(/^I should stop being a member of project "([^"]*)"$/) do |name|
  object = Project.find_by_title(name)
  @user.stop_following(object)
end
When(/^I am not a member of project "([^"]*)"$/) do |name|
  step %Q{I should stop being a member of project "#{name}"}
end

Given(/^I am on the home page$/) do
  visit "/"
end

Then(/^(.*) in the project members list$/) do |s|
  within(:css, '#members_list') do
    step s
  end
end

When(/^I go to the next page$/) do
  first(:css, 'a', text: 'Next').click()
end

Given(/^I (?:am on|go to) project "([^"]*)"$/) do |project|
  project.downcase!
  project = Project.find_by_title(project)
  visit(path_to('projects', project.id ))
end

Given(/^the document "([^"]*)" has a sub-document with title "([^"]*)" created (\d+) days ago$/) do |parent, child, arg3|
  parent_doc = Document.find_by_title(parent)
  parent_doc.children.create!(
      {
          :project_id => parent_doc.project_id,
          :title => child,
          :created_at => arg3,
          user_id: parent_doc.user_id
      }
  )
end


And(/^the following sub-documents exist:$/) do |table|
  table.hashes
end


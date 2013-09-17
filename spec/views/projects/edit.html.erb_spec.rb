require 'spec_helper'

describe "projects/edit.html.erb" do
  before :each do
    @project = Project.create :title => "test title", :description => "test content"
    render :template => "projects/edit", :id => "test-title"
  end

  it "displays a 'Edit project' heading" do
    rendered.should have_selector('h1', :text => "Edit project")
  end

  it "an edit form" do
    rendered.should have_selector('form.edit_project')
  end

  context "the edit form in contains" do
    it "contains a title edit field" do
      rendered.should have_selector 'form input#project_title'
      rendered.should have_xpath "//input[@value='test title']"
    end

    it "contains a description edit field" do
      rendered.should have_selector 'form textarea#project_description',
        :text => "test content"
    end

    it "contains an active checkbox" do
      rendered.should have_selector 'form input#project_active'
      rendered.should have_xpath "//input[@name= 'project[active]' and @type='checkbox' and @value='1']"
    end
  end
end

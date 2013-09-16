require 'spec_helper'

describe "projects/index.html.erb" do
  before :each do
    fake_project = Project.create :title => "test title", :description => "test content"
    fake_project_two = Project.create :title => "test title two", :description => "test content two"
    @projects = [fake_project, fake_project_two]
    render :template => "projects/index", :projects => Project.all
  end

  it "displays a 'Projects' heading" do
    rendered.should have_selector('h1', :text => "Projects")
  end

  it "displays a list of projects, each with a title" do
    rendered.should have_selector('li h2', :text => "test title")
  end

  it "displays a list of projects, each with a description" do
    rendered.should have_selector('li p', :text => "test content")
  end

  # TODO
  context "the user is authenticated" do
    xit "displays a 'New Project' link" do
      ApplicationHelper.stub(:logged_in?).and_return true
      render :template => "projects/index", :projects => Project.all
      rendered.should have_selector('a', :text => "New Project")
    end
  end
end

require 'spec_helper'

describe "projects/new.html.erb" do
  before :each do
    @project = Project.new
    render :template => "projects/new"
  end

  it "displays a 'New Project' heading" do
    rendered.should have_selector('h1', :text => "New project")
  end

  it "displays a form" do
    rendered.should have_selector('form')
  end

  it "displays a 'Back' button" do
    rendered.should have_selector('a', :text => 'Back')
  end
end

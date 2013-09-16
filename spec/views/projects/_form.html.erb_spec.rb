require 'spec_helper'

describe "projects/_form.html.erb" do

  before :each do
    @project = Project.create :title => 'foo'
    render :template => "projects/_form"
  end

  it "renders a form element" do
    rendered.should have_selector 'form'
  end

  it "renders a form with an 'Active' field" do
    rendered.should have_selector 'label', :text => 'Active'
  end
end

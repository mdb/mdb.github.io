require 'spec_helper'

describe "projects/_form.html.erb" do

  before :each do
    @project = Project.create :title => 'foo bar'
    render :template => "projects/_form"
  end

  it "renders a form element" do
    rendered.should have_selector 'form'
  end

  context "the form it renders" do
    it "has a 'title' input field" do
      rendered.should have_selector 'input#project_title'
      rendered.should have_xpath "//input[@value='foo bar' and @type='text']"
    end

    # TODO
    xit "has a 'description' input field" do
      #pending
    end

    it "has an 'Active' field" do
      rendered.should have_selector 'label', :text => 'Active'
    end

    # TODO: why isn't this working?
    xit "renders 6 file uploaders" do
      rendered.should have_selector 'input#project_project_assets_attributes_0_project_assets'
    end
  end

  # TODO
  context "the form contains a title that's too short" do
    xit "renders an error" do
      #pending
    end
  end

  # TODO
  context "the form does not contain a title" do
    xit "renders an error" do
      #pending
    end
  end
end

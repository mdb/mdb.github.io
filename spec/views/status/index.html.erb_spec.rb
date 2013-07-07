require 'spec_helper'

describe "status/index.html.erb" do
  before :each do
    @revision = {
      :id => 'some_id',
      :message => 'some_message'
    }
    render :template => "status/index", :layout => 'layouts/status'
  end

  it "displays a 'Status' heading" do
    rendered.should have_selector('h1', :text => "Status")
  end

  context "the version control details it reports" do
    it "renders a revision heading" do
      rendered.should have_selector('dl dt', :text => "Revision")
    end

    it "reports revision id" do
      rendered.should have_selector('dl dd', :text => "some_id")
    end

    it "reports revision message" do
      rendered.should have_selector('dl dd', :text => "some_message")
    end
  end
end

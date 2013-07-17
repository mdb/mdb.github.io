require 'spec_helper'

describe "status/index.html.erb" do
  before :each do
    @fingerprint = {
      :some_key => 'some value',
      :another_key => 'another value'
    }
    render :template => "status/index", :layout => 'layouts/status'
  end

  it "displays a 'Status' heading" do
    rendered.should have_selector('h1', :text => "Status")
  end

  it "renders a definition list reporting all the keys/values contained in the @fingerprint hash" do
    rendered.should have_selector('dl dt', :text => "some_key")
    rendered.should have_selector('dl dd', :text => "some value")
    rendered.should have_selector('dl dt', :text => "another_key")
    rendered.should have_selector('dl dd', :text => "another value")
  end
end

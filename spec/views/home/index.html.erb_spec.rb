require 'spec_helper'

describe "home/index.html.erb" do
  before :each do
    render :template => "home/index", :layout => 'layouts/application'
  end

  it "displays a 'Hello World' heading" do
    rendered.should have_selector('h1', :text => "Hello World")
  end
end

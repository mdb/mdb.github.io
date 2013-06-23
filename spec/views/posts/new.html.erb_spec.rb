require 'spec_helper'

describe "posts/new.html.erb" do
  before :each do
    @post = Post.new
    render :template => "posts/new"
  end

  it "displays a 'New Post' heading" do
    rendered.should have_selector('h1', :text => "New post")
  end

  it "displays a form" do
    rendered.should have_selector('form')
  end

  it "displays a 'Back' button" do
    rendered.should have_selector('a', :text => 'Back')
  end
end

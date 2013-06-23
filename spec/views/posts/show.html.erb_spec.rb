require 'spec_helper'

describe "posts/show.html.erb" do
  before :each do
    @post = Post.create :title => "test title", :content => "test content"
    render :template => "posts/show"
  end

  it "displays a post title" do
    rendered.should have_selector('h1', :text => "test title")
  end

  it "displays post content" do
    rendered.should have_selector('p', :text => "test content")
  end
end

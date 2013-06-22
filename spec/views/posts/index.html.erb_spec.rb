require 'spec_helper'

describe "posts/index.html.erb" do
  before :each do
    fake_post = Post.create :title => "test title", :content => "test content"
    @posts = [fake_post, fake_post]
    render :template => "posts/index", :posts => Post.all
  end

  it "displays a 'Posts' heading" do
    rendered.should have_selector('h1', :text => "Posts")
  end

  it "displays a list of posts, each with a title" do
    rendered.should have_selector('li h2', :text => "test title")
  end

  it "displays a list of posts, each with content" do
    rendered.should have_selector('li p', :text => "test content")
  end
end

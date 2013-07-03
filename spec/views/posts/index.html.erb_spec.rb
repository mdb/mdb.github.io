require 'spec_helper'

describe "posts/index.html.erb" do
  before :each do
    fake_post = Post.create(:title => "test title", :content => "test content", :tag_list => ['fake_tag'])
    fake_post_without_tag = Post.create(:title => "tagless post", :content => "test content")
    @posts = [fake_post, fake_post, fake_post_without_tag]
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

  it "displays a list of posts and displays tags for those posts which are tagged" do
    rendered.should have_selector('li a', :text => "fake_tag")
  end

  it "displays a 'New Post' link" do
    rendered.should have_selector('a', :text => "New Post")
  end
end

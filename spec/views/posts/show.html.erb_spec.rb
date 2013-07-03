require 'spec_helper'

describe "posts/show.html.erb" do
  before :each do
    @post = Post.create(
      :title => "test title",
      :content => "test content",
      :tag_list => ["some_tag"]
    )
    render :template => "posts/show"
  end

  it "displays a post title" do
    rendered.should have_selector('h1', :text => "test title")
  end

  it "displays the date published" do
    date = "Published #{Time.now.strftime("%B %-d, %Y")}"
    rendered.should have_selector('date', :text => date)
  end

  it "displays post content" do
    rendered.should have_selector('p', :text => "test content")
  end

  context "the post has tags" do
    it "displays post tags" do
      rendered.should have_selector('a',
        :text => "some_tag"
      )
    end
  end

  context "the post does not have tags" do
    before :each do
      @post = Post.create(
        :title => "test title",
        :content => "some test content"
      )
    end
    it "does not display post tags" do
      rendered.should have_content 'Tags'
    end
  end
end

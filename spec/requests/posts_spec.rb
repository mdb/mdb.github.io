require 'spec_helper'

describe "Posts" do
  describe "GET /posts" do
    it "returns a 200" do
      get posts_path
      response.status.should be(200)
    end

    it "displays some posts" do
      @post = Post.create :title => "Test Post", :content => "test content"
      visit posts_path
      page.should have_content "Test Post"
      page.should have_content "test content"
    end
  end
end

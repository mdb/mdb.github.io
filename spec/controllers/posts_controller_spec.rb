require 'spec_helper'

describe PostsController do

  describe "GET 'index'" do
    before :each do
      get 'index'
    end

    it "returns http success" do
      response.should be_success
    end

    it "creates a @posts instance variable with all the posts" do
      assigns(:posts).should eq Post.all      
    end
  end

  describe "GET 'new'" do
    before :each do
      get 'new'
    end

    it "returns http success" do
      response.should be_success
    end

    it "creates a new post in a @post instance variable" do
      assigns(:post).class.should eq Post
    end
  end

  describe "POST 'create'" do
    before :each do
      post 'create'
    end

    it "redirects to the post's permalink" do
      response.should redirect_to('/posts/1')
    end
  end

  describe "GET 'show'" do
    before :each do
      @post = Post.create(:title => "test title", :content => "")
      get 'show', :id => 1 
    end

    it "returns http success" do
      response.should be_success
    end
  end
end

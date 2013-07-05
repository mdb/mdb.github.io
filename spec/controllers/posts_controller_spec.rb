require 'spec_helper'
require 'pry'

describe PostsController do

  describe "GET 'index'" do
    before :each do
      Post.create(:title => "inactive post", :active => false)
      Post.create(:title => "active post")
      Post.create(:title => "active post two")
      get :index
    end

    it "returns http success" do
      response.should be_success
    end

    it "creates a @posts instance variable with all the active posts" do
      assigns(:posts).should eq Post.where(:active => true).sort_by(&:created_at).reverse
    end

    it "sorts the posts in order of most recently created to least recently created" do
      assigns(:posts)[0].title.should eq 'active post two'
    end

    it "does not return inactive posts" do
      assigns(:posts).any?{ |post| post.title == 'inactive post'}.should == false
    end
  end

  describe "GET 'new'" do
    context "the user is not authenticated" do
      before :each do
        get :new
      end

      it "does not return http success" do
        response.should_not be_success
      end
    end

    context "the user is authenticated" do
      before :each do
        http_login
        get :new
      end

      it "returns http success" do
        response.should be_success
      end

      it "creates a new post in a @post instance variable" do
        assigns(:post).class.should eq Post
      end
    end
  end

  describe "POST 'create'" do
    context "the user is authenticated" do
      before :each do
        http_login
        post :create, :post => {:title => "some fake title"}
      end

      it "redirects to the post's permalink" do
        response.should redirect_to('/posts/some-fake-title')
      end
    end
  end

  describe "GET 'show'" do
    before :each do
      @post = Post.create(:title => "test title", :content => "")
      get :show, :id => 1
    end

    it "returns http success" do
      response.should be_success
    end
  end
end

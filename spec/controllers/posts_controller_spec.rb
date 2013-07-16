require 'spec_helper'

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

    context "the user is not authenticated" do
      it "creates a @posts instance variable with all the active posts" do
        assigns(:posts).should eq Post.where(:active => true).sort_by(&:created_at).reverse
      end

      it "does not return inactive posts" do
        assigns(:posts).any?{ |post| post.title == 'inactive post'}.should == false
      end
    end

    it "sorts the posts in order of most recently created to least recently created" do
      assigns(:posts)[0].title.should eq 'active post two'
    end

    context "the user is authenticated" do
      before :each do
        http_login
        get :index
      end

      it "creates a @posts instance variable with all the posts" do
        assigns(:posts).should eq Post.all.sort_by(&:created_at).reverse
      end

      it "returns inactive posts" do
        assigns(:posts).any?{ |post| post.title == 'inactive post'}.should eq true
      end
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
      @a_post = Post.create(:title => "test title", :content => "test content")
      get :show, :id => 'test-title'
    end

    it "returns http success" do
      response.should be_success
    end

    it "returns the correct post" do
      assigns(:post).should eq @a_post
    end
  end

  describe "DELETE 'destroy'" do
    before :each do
      @a_post = Post.create(:title => "test title", :content => "test content")
    end

    context "the user is logged in" do
      before :each do
        http_login
      end

      it "deletes the post" do
        Post.all.count.should eq 1
        Post.first.title.should eq 'test title'
        delete :destroy, :id => 'test-title'
        Post.all.count.should eq 0
      end

      it "redirects to the posts page" do
        delete :destroy, :id => 'test-title'
        response.should redirect_to(posts_path)
      end
    end

    context "the user is not logged in" do
      it " does not delete the post" do
        Post.all.count.should eq 1
        Post.first.title.should eq 'test title'
        delete :destroy, :id => 'test-title'
        Post.all.count.should eq 1
      end

      it "does not redirect to the posts page" do
        delete :destroy, :id => 'test-title'
        response.status.should eq 401
      end
    end
  end
end

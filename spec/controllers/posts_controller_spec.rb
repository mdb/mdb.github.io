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

end

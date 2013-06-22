require 'spec_helper'

describe "Posts" do
  describe "GET /posts" do
    it "returns a 200" do
      get posts_path
      response.status.should be(200)
    end
  end
end

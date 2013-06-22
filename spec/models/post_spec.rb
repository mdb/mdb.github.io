require 'spec_helper'

describe Post do
  before :each do
    @post = Post.new
  end

  describe "#title" do
    it "exists as a method on a Post" do
      @post.respond_to?(:title).should eq true
    end
  end

  describe "#content" do
    it "exists as a method on a Post" do
      @post.respond_to?(:content).should eq true
    end
  end
end

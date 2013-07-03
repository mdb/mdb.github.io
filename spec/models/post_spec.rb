require 'spec_helper'

describe Post do
  before :each do
    @post = Post.new
  end

  describe "#title" do
    it "exists as a method on a Post" do
      @post.respond_to?(:title).should eq true
    end

    it "is required" do
      Post.new(:title => nil).should_not be_valid
    end

    it "must be 5 characters" do
      Post.new(:title => 'four').should_not be_valid
      Post.new(:title => 'at least five chars').should be_valid
    end

    xit "accepts nested tag attributes" do
      @post.should accept_nested_attributes_for :tags
    end
  end

  describe "#content" do
    it "exists as a method on a Post" do
      @post.respond_to?(:content).should eq true
    end
  end
end

require 'spec_helper'

describe Tag do
  before :each do
    @tag = Tag.new :name => 'tag name'
  end

  xit "belongs to Post" do
    @tag.respond_to?(:post_id).should eq true
  end

  describe "#name" do
    xit "exists as a public method on a Tag" do
      @tag.name.should eq 'tag name'
    end
  end
end

require 'spec_helper'

describe Project do
  before :each do
    @project = Project.new
  end

  describe "#title" do
    it "exists as a method on a Project" do
      @project.respond_to?(:title).should eq true
    end

    it "is required" do
      Project.new(:title => nil).should_not be_valid
    end
  end

  describe "#description" do
    it "exists as a method on a Project" do
      @project.respond_to?(:description).should eq true
    end
  end
end

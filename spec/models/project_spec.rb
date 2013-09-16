require 'spec_helper'

describe Project do
  before :each do
    @project = Project.new(:title => "Some Title")
  end

  describe "#title" do
    it "returns the project's title" do
      @project.title.should eq "Some Title"
    end

    it "is required" do
      Project.new(:title => nil).should_not be_valid
    end

    it "must be 5 characters" do
      Project.new(:title => 'four').should_not be_valid
      Project.new(:title => 'at least five chars').should be_valid
    end
  end

  describe "#description" do
    it "exists as a method on a Project" do
      @project.respond_to?(:description).should eq true
    end
  end

  describe "#slug" do
    it "exists as a method on a Project" do
      @project.respond_to?(:slug).should eq true
    end
  end

  describe "#active" do
    it "exists as a method on a Project" do
      @project.respond_to?(:active).should eq true
    end

    it "is true by default" do
      @project.active.should eq true
    end
  end

  describe "#permalink" do
    it "returns the Project's permalink" do
      @project.permalink.should eq '/projects/some-title'
    end
  end
end

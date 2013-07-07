require 'spec_helper'

describe StatusController do
  describe "#index" do
    before :each do
    end

    it "returns http success" do
      get 'index'
      response.should be_success
    end

    it "creates a @revision hash to house information about the codebase repo" do
      get 'index'
      assigns(:revision).class.should eq Hash
    end
  end
end

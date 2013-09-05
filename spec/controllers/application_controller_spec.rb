require 'spec_helper'

describe ApplicationController do
  controller do
    def index
      render :text => "Hello"
    end
  end

  context "the app is configured to report git revision info in its fingerprint" do
    it "creates @fingerprint hash to house information about the codebase" do
      get 'index'
      assigns(:fingerprint).class.should eq Hash
    end
  end

  context "the app is not configured to report git revision info in its fingerprint" do
    it "does not create a @fingerprint instance variable" do
      Mdb::Application.config.stub(:git_fingerprint_activated).and_return false
      get 'index'
      assigns(:fingerprint).should eq nil
    end
  end
end

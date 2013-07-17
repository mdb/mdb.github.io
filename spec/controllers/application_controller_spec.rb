require 'spec_helper'

describe ApplicationController do
  controller do
    def index
      render :text => "Hello"
    end
  end

  it "creates @fingerprint hash to house information about the codebase" do
    get 'index'
    assigns(:fingerprint).class.should eq Hash
  end
end

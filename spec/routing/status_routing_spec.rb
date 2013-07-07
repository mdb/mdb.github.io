require "spec_helper"

describe "StatusController" do
  describe "routing" do
    it "routes to #index" do
      get("/_status").should route_to("status#index")
    end
  end
end

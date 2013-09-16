require "spec_helper"

describe "ProjectController" do
  describe "routing" do
    it "routes to a projects index" do
      get("/projects").should route_to("projects#index")
    end

    it "routes to an individual project view" do
      get("/projects/foo").should route_to(
        "action" => "show",
        "controller" => "projects",
        "id" => "foo"
      )
    end

    it "routes to a view for creating new projects" do
      get("/projects/new").should route_to("projects#new")
    end
  end
end

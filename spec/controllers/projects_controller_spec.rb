require 'spec_helper'

describe ProjectsController do

  describe "GET 'index'" do
    before :each do
      Project.create(:title => "inactive project", :active => false)
      Project.create(:title => "active project")
      Project.create(:title => "active project two")
      get :index
    end

    it "returns http success" do
      response.should be_success
    end

    context "the user is not authenticated" do
      it "creates a @projects instance variable with all the active projects" do
        assigns(:projects).should eq Project.where(:active => true).sort_by(&:created_at).reverse
      end

      it "does not return inactive projects" do
        assigns(:projects).any?{ |project| project.title == 'inactive project'}.should == false
      end
    end

    it "sorts the projects in order of most recently created to least recently created" do
      assigns(:projects)[0].title.should eq 'active project two'
    end

    context "the user is authenticated" do
      before :each do
        http_login
        get :index
      end

      it "creates a @projects instance variable with all the projects" do
        assigns(:projects).should eq Project.all.sort_by(&:created_at).reverse
      end

      it "returns inactive projects" do
        assigns(:projects).any?{ |project| project.title == 'inactive project'}.should eq true
      end
    end
  end

  describe "GET 'new'" do
    context "the user is not authenticated" do
      before :each do
        get :new
      end

      it "does not return http success" do
        response.should_not be_success
      end
    end

    context "the user is authenticated" do
      before :each do
        http_login
        get :new
      end

      it "returns http success" do
        response.should be_success
      end

      it "creates a new project in a @project instance variable" do
        assigns(:project).class.should eq Project
      end

      # TODO: how to test this?
      xit "builds 6 project asset fields" do
        project = double Project
        project.project_assets.should_receive(:build).exactly(6).times
        get :new
      end
    end
  end

  describe "POST 'create'" do
    context "the user is authenticated" do
      before :each do
        http_login
        post :create, :project => {:title => "some fake title"}
      end

      it "redirects to the project's permalink" do
        response.should redirect_to('/projects/some-fake-title')
      end
    end
  end

  describe "GET 'show'" do
    before :each do
      @a_project = Project.create(:title => "test title", :description => "test description")
      get :show, :id => 'test-title'
    end

    it "returns http success" do
      response.should be_success
    end

    it "returns the correct post" do
      assigns(:project).should eq @a_project
    end
  end

  describe "DELETE 'destroy'" do
    before :each do
      @a_project = Project.create(:title => "test title", :description => "test description")
    end

    context "the user is logged in" do
      before :each do
        http_login
      end

      it "deletes the project" do
        Project.all.count.should eq 1
        Project.first.title.should eq 'test title'
        delete :destroy, :id => 'test-title'
        Project.all.count.should eq 0
      end

      it "redirects to the projects page" do
        delete :destroy, :id => 'test-title'
        response.should redirect_to(projects_path)
      end
    end

    context "the user is not logged in" do
      it "does not delete the project" do
        Project.all.count.should eq 1
        Project.first.title.should eq 'test title'
        delete :destroy, :id => 'test-title'
        Project.all.count.should eq 1
      end

      it "does not redirect to the projects page" do
        delete :destroy, :id => 'test-title'
        response.status.should eq 401
      end
    end
  end

  describe "GET 'edit'" do
    before :each do
      @a_project = Project.create(:title => "test title", :description => "test description")
    end

    # TODO: how to test this?
    xit "builds 6 project asset fields" do
      project = double Project
      project.project_assets.should_receive(:build).exactly(6).times
      get :edit, id: "test-title"
    end
  end
end

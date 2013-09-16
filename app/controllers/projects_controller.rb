class ProjectsController < ApplicationController
  http_basic_authenticate_with name: Mdb::Application.config.username, password: Mdb::Application.config.password, except: [:index, :show]

  def index
    query = logged_in? ? Project.all : Project.where(:active => true)

    if params[:tag]
      @projects = query.tagged_with(params[:tag]).sort_by(&:created_at).reverse
    else
      @projects = query.sort_by(&:created_at).reverse
    end
  end

  def new
    @project = Project.new
  end

  def edit
    @project = Project.find_by_slug(params[:id])
  end

  def create
    @project = Project.new(app_params)

    respond_to do |format|
      if @project.save
        format.html  { redirect_to(@project,
          :notice => 'Project was successfully created.') }
      else
        format.html  { render :action => "new" }
      end
    end
  end

  def update
    @project = Project.find_by_slug(params[:id])

    respond_to do |format|
      if @project.update_attributes(app_params)
        format.html { redirect_to(@project, :notice => 'Project was successfully updated.') }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def show
    @project = Project.find_by_slug(params[:id])
  end

  def destroy
    @project = Project.find_by_slug(params[:id])
    @project.destroy

    respond_to do |format|
      format.html { redirect_to projects_url }
    end
  end

  private
  def app_params
    params.require(:project).permit(:title, :description, :updated_at, :created_at, :active, :tag_list)
  end

  def logged_in?
    !request.authorization.nil?
  end
end

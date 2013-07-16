class PostsController < ApplicationController
  http_basic_authenticate_with name: Mdb::Application.config.username, password: Mdb::Application.config.password, except: [:index, :show]

  def index
    query = logged_in? ? Post.all : Post.where(:active => true)

    if params[:tag]
      @posts = query.tagged_with(params[:tag]).sort_by(&:created_at).reverse
    else
      @posts = query.sort_by(&:created_at).reverse
    end
  end

  def new
    @post = Post.new
  end

  def edit
    @post = Post.find_by_slug(params[:id])
  end

  def create
    @post = Post.new(app_params)

    respond_to do |format|
      if @post.save
        format.html  { redirect_to(@post,
          :notice => 'Post was successfully created.') }
      else
        format.html  { render :action => "new" }
      end
    end
  end

  def update
    @post = Post.find_by_slug(params[:id])

    respond_to do |format|
      if @post.update_attributes(app_params)
        format.html { redirect_to(@post, :notice => 'Post was successfully updated.') }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def show
    @post = Post.find_by_slug(params[:id])
  end

  def destroy
    @post = Post.find_by_slug(params[:id])
    @post.destroy

    respond_to do |format|
      format.html { redirect_to posts_url }
    end
  end

  private
  def app_params
    params.require(:post).permit(:title, :content, :updated_at, :created_at, :active, :tag_list, :thumbnail)
  end

  def logged_in?
    !request.authorization.nil?
  end
end

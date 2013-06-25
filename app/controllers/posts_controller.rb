class PostsController < ApplicationController
  def index
    @posts = Post.all
  end

  def new
    @post = Post.new
  end

  def edit
    @post = Post.find_by_slug(params[:id])
  end

  def create
    @post = Post.new(params[:post])

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
      if @post.update_attributes(params[:post])
        format.html { redirect_to(@post, :notice => 'Post was successfully updated.') }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def show
    @post = Post.find_by_slug(params[:id])
  end
end

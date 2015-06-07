class RailsPostsController < ApplicationController
  respond_to :json

  def index
    @posts = Post.all
  end

  def show
    @post = Post.find(params[:id])
  end
end

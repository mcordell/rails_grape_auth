module RailsApi
  class RailsPostsController < ApplicationController
    include DeviseTokenAuth::Concerns::SetUserByToken
    before_action :authenticate_user!
    respond_to :json

    def index
      @posts = Post.all
    end

    def show
      @post = Post.find(params[:id])
    end
  end
end

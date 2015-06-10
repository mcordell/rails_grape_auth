module GrapeApi
  class Posts < Grape::API
    format :json

    get '/' do
      present Post.all
    end
  end
end

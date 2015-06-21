GrapeDeviseTokenAuth.setup! do |config|
  config.authenticate_all = false
end

module GrapeApi
  class Posts < Grape::API
    auth :grape_devise_token_auth, resource_class: :user

    format :json

    helpers GrapeDeviseTokenAuth::AuthHelpers

    get '/' do
      authenticate_user!
      present Post.all
    end

    get '/helper_test' do
      authenticate_user!
      {
        current_user_uid: current_user.uid,
        authenticated?: authenticated?
      }
    end

    get '/unauthenticated_helper_test' do
      {
        current_user: current_user,
        authenticated?: authenticated?
      }
    end
  end
end

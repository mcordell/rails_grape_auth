GrapeDeviseTokenAuth.setup!(true)

module GrapeApi
  class Posts < Grape::API
    auth :grape_devise_token_auth, resource_class: :user

    format :json

    helpers GrapeDeviseTokenAuth::AuthHelpers

    get '/' do
      present Post.all
    end

    get '/helper_test' do
      {
        current_user_uid: current_user.uid,
        authenticated?: authenticated?
      }
    end
  end
end

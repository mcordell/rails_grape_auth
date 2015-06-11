class AuthMiddleware
  def initialize(app, args)
    @app = app
    @args = args
  end

  def call(env)
    binding.pry
    return @app.call(env)
  end
end

Grape::Middleware::Auth::Strategies.add(:my_auth, AuthMiddleware, ->(options) { [options[:realm]] } )

module GrapeApi
  class Posts < Grape::API
    auth :my_auth, { realm: 'Test Api'}

    format :json

    get '/' do
      present Post.all
    end
  end
end

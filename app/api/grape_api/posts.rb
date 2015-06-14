class GrapeDeviseTokenAuth
  ACCESS_TOKEN_KEY = 'HTTP_ACCESS_TOKEN'
  EXPIRY_KEY = 'HTTP_EXPIRY'
  UID_KEY = 'HTTP_UID'
  CLIENT_KEY = 'HTTP_CLIENT'

  attr_reader :uid, :client_id, :token, :expiry, :user

  def initialize(app, args)
    @app = app
    @args = args
  end

  def call(env)
    setup(env)
    return unauthorized unless authenticated_by_token?
    responses_with_auth_headers(*@app.call(env))
  end

  private

  def setup(env)
    @uid         = env[UID_KEY]
    @client_id   = env[CLIENT_KEY]
    @token       = env[ACCESS_TOKEN_KEY]
    @expiry      = env[EXPIRY_KEY]
  end

  def authenticated_by_token?
    @user = User.find_by_uid(uid)
    user && user.valid_token?(token, client_id)
  end

  def valid?
    keys_present? && !expired?
  end

  def keys_present?
    uid.present? && client_id.present? && token.present?
  end

  def expired?
    env[EXPIRY_KEY].to_i < Time.now.to_i
  end

  def responses_with_auth_headers(status, headers, response)
    [
      status,
      headers.merge(auth_headers),
      response
    ]
  end

  def auth_headers
    user.with_lock do
      return user.create_new_auth_token(client_id)
    end
  end

  def unauthorized
    [401,
     { 'Content-Type' => 'application/json'
     },
     []
    ]
  end
end

Grape::Middleware::Auth::Strategies.add(:my_auth, GrapeDeviseTokenAuth, ->(options) { [options[:realm]] } )

module GrapeApi
  class Posts < Grape::API
    auth :my_auth, { realm: 'Test Api'}

    format :json

    get '/' do
      present Post.all
    end
  end
end

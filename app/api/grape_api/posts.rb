class GrapeDeviseTokenAuth
  ACCESS_TOKEN_KEY = 'HTTP_ACCESS_TOKEN'
  EXPIRY_KEY = 'HTTP_EXPIRY'
  UID_KEY = 'HTTP_UID'
  CLIENT_KEY = 'HTTP_CLIENT'

  def initialize(app, args)
    @app = app
    @args = args
  end

  def call(env)
    setup(env)
    user = authenticate_from_token
    return unauthorized unless user
    sign_in_user(user)
    responses_with_auth_headers(*@app.call(env))
  end

  private

  attr_reader :uid, :client_id, :token, :expiry, :user, :resource_class, :resource, :warden, :batch_request_buffer_throttle, :request_start

  def setup(env)
    @request_start = Time.now
    @uid           = env[UID_KEY]
    @client_id     = env[CLIENT_KEY] || 'default'
    @token         = env[ACCESS_TOKEN_KEY]
    @expiry        = env[EXPIRY_KEY]
    @warden        = env['warden']
  end

  def sign_in_user(user)
    # user already logged in from devise:
    return resource if resource
    @resource = user
  end

  def resource_from_existing_devise_user
    warden_user =  warden.user(resource_class.to_s.underscore.to_sym)
    return unless warden_user && warden_user.tokens[client_id].nil?
    @resource = warden_user
    @resource.create_new_auth_token
  end

  def authenticate_from_token(mapping = nil)
    resource_class_from_mapping(mapping)
    return nil unless resource_class

    resource_from_existing_devise_user
    return resource if correct_resource_type_logged_in?

    return nil unless token_request_valid?

    user = resource_class.find_by_uid(uid)

    return nil unless user && user.valid_token?(token, client_id)

    user
  end

  def token_request_valid?
    token && uid
  end

  def correct_resource_type_logged_in?
    resource && resource.class == resource_class
  end

  def resource_class_from_mapping(_mapping)
    @resource_class = User
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
    return {} unless resource && resource.valid? && client_id
    auth_headers_from_resource
  end

  def auth_headers_from_resource
    auth_headers = {}
    resource.with_lock do
      if !DeviseTokenAuth.change_headers_on_each_request
        auth_headers = resource.extend_batch_buffer(token, client_id)
      elsif batch_request?
        resource.extend_batch_buffer(token, client_id)
        # don't set any headers in a batch request
      else
        auth_headers = resource.create_new_auth_token(client_id)
      end
    end
    auth_headers
  end

  def unauthorized
    [401,
     { 'Content-Type' => 'application/json'
     },
     []
    ]
  end

  def batch_request?
    @batch_request ||= resource.tokens[client_id] &&
                       resource.tokens[client_id]['updated_at'] &&
                       within_batch_request_window?
  end

  def within_batch_request_window?
    end_of_window = Time.parse(resource.tokens[client_id]['updated_at']) +
                    DeviseTokenAuth.batch_request_buffer_throttle
    request_start < end_of_window
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

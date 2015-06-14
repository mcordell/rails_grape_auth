require 'rails_helper'

RSpec.describe 'Getting a protected route on the grape API', type: :request do
  let(:protected_route) { '/grape_api' }
  let(:resource_class) { User }
  let(:resource) do
    resource_class.create(
      uid:                   'test@example.com',
      email:                 'test@example.com',
      provider:              'email',
      created_at:            Time.now,
      updated_at:            Time.now,
      password:              'secret123',
      password_confirmation: 'secret123'
    )
  end
  let(:auth_headers) { resource.create_new_auth_token }
  let(:token)        { auth_headers['access-token'] }
  let(:client_id)    { auth_headers['client'] }
  let(:expiry)       { auth_headers['expiry'] }

  describe 'successful request' do
    before do
      age_token(resource, client_id)

      get protected_route, {}, auth_headers

      @resp_token       = response.headers['access-token']
      @resp_client_id   = response.headers['client']
      @resp_expiry      = response.headers['expiry']
      @resp_uid         = response.headers['uid']
    end

    it 'should return success status' do
      expect(response.status).to eq 200
    end

    it 'should receive new token after successful request' do
      expect(@resp_token).not_to eq token
    end

    it 'should preserve the client id from the first request' do
      expect(client_id).to eq @resp_client_id
    end

    it "should return the user's uid in the auth header" do
      expect(resource.uid).to eq @resp_uid
    end
  end

  describe 'failed request' do
    before do
      get '/grape_api/', {}, auth_headers.merge(
        'access-token' => 'bogus')
    end

    it 'should not return any auth headers' do
      expect(response.headers).not_to have_key 'access-token'
    end

    it 'should return error: unauthorized status' do
      expect(response.status).to eq 401
    end
  end

  private

  def age_token(user, client_id)
    age = Time.now -
          (DeviseTokenAuth.batch_request_buffer_throttle + 10.seconds)
    user.tokens[client_id]['updated_at'] = age
    user.save!
  end
end

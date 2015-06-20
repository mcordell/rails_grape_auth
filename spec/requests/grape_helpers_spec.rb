require 'rails_helper'

RSpec.describe 'Getting a protected route' do
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

  context 'that demonstrates the helper methods' do
    before do
      age_token(resource, client_id)

      get '/grape_api/helper_test', {}, auth_headers
      @helper_response = JSON.parse(response.body)
    end

    it 'current user returns the signed in user' do
      expect(@helper_response['current_user_uid']).to eq resource.uid
    end

    it 'authenticated? returns true when the user is authenticated' do
      expect(@helper_response['authenticated?']).to eq true
    end
  end
end

require 'rails_helper'

RSpec.describe ApplicationsController, type: :controller do
  describe 'POST #create' do
    let(:valid_attributes) { { application: { name: 'Test App' } } }

    context 'with valid parameters' do
      it 'creates a new application' do
        post :create, params: valid_attributes
        expect(response).to have_http_status(:created)

        application = Application.last
        expect(application).to be_present
        expect(application.name).to eq(valid_attributes[:application][:name])
        expect(application.chats_count).to eq(0)
        expect(application.token).to be_present

        validate_id_and_timestamps_not_returned
        expect(response_json['token']).to eq(application.token)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) { { application: { name: '' } } }

      it 'returns bad request status' do
        post :create, params: invalid_attributes

        expect(response).to have_http_status(:bad_request)
        expect(response_json).to include('name' => ['can\'t be blank'])
      end
    end
  end

  describe 'GET #show' do
    let!(:application) { FactoryBot.create(:application) }

    context 'when application exists' do
      it 'returns the application details' do
        get :show, params: { token: application.token }

        expect(response).to have_http_status(:ok)
        response_data = response_json
        expect(response_data['name']).to eq(application.name)
        expect(response_data['chats_count']).to eq(application.chats_count)
        expect(response_data['token']).to eq(application.token)
        validate_id_and_timestamps_not_returned
      end
    end

    context 'when application does not exist' do
      it 'returns 404 status' do
        get :show, params: { token: 'invalid_token' }

        expect(response).to have_http_status(404)
        expect(response_json).to eq('error' => 'Application not Found')
      end
    end
  end

  describe 'PATCH #update' do
    let!(:application) { FactoryBot.create(:application) }

    context 'with valid parameters' do
      let(:new_name) { 'Updated App Name' }
      let(:valid_update_params) { { token: application.token, application: { name: new_name } } }

      it 'updates the application' do
        patch :update, params: valid_update_params

        expect(response).to have_http_status(:ok)
        expect(response_json['name']).to eq(new_name)
        validate_id_and_timestamps_not_returned

        application = Application.last
        expect(application).to be_present
        expect(application.name).to eq(new_name)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_update_params) { { token: application.token, application: { name: '' } } }

      it 'returns bad_request status' do
        patch :update, params: invalid_update_params

        expect(response).to have_http_status(:bad_request)
        expect(response_json['errors']).to include('name' => ['can\'t be blank'])
      end
    end

    context 'when application does not exist' do
      let(:invalid_token_params) { { token: 'invalid_token', application: { name: 'New Name' } } }

      it 'returns not found status' do
        patch :update, params: invalid_token_params

        expect(response).to have_http_status(:not_found)
        expect(response_json).to eq('error' => 'Application not Found')
      end
    end
  end

  private

  def response_json
    JSON.parse(response.body)
  end

  def validate_id_and_timestamps_not_returned
    response_data = response_json
    expect(response_data['id']).to be_nil
    expect(response_data['created_at']).to be_nil
    expect(response_data['updated_at']).to be_nil
  end
end

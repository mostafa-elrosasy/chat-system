require 'rails_helper'

RSpec.describe ChatsController, type: :controller do
  let(:application_token) { 'application_token' }
  let(:application) { FactoryBot.create(:application) }
  let(:other_application) { FactoryBot.create(:application) }

  describe 'POST #create' do
    before do
      allow(SecureRandom).to receive(:uuid).and_return('fake_uuid')
      allow($redis).to receive(:incr).and_return(1)
      allow($redis).to receive(:lpush).and_return(Rails.configuration.chats_batch_size + 1)
      allow(CreateChatsJob).to receive(:perform_async)
    end

    it 'adds new chat data correctly to the queue' do
      post :create, params: { application_token: application.token }

      expect(response).to have_http_status(:created)
      expect(response_json['number']).to eq(1)
      expect(response_json['messages_count']).to eq(0)
      validate_id_and_timestamps_not_returned()
      expect($redis).to have_received(:incr).with(
        "#{Rails.configuration.redis_chats_number_key_prefix}_#{application.id}"
      )

      expect(Chat.count).to eq(0)

      expect($redis).to have_received(:lpush).with(
        "chats",
        {
            "number"=>1,
            "messages_count"=>0,
            "application_id"=>application.id
        }.to_json
      )
    end

    it 'enqueues a job when queue size is greater than or equal to batch size' do
      allow($redis).to receive(:lpush).and_return(Rails.configuration.chats_batch_size)

      post :create, params: { application_token: application.token }

      expect(CreateChatsJob).to have_received(:perform_async).with('fake_uuid')
    end

    it 'doesnt enqueue a job when queue size is less than to batch size' do
      allow($redis).to receive(:lpush).and_return(Rails.configuration.chats_batch_size - 1)

      post :create, params: { application_token: application.token }

      expect(CreateChatsJob).to_not have_received(:perform_async)
    end

    it 'renders error response when application is not found' do
      post :create, params: { application_token: 'invalid_token' }

      expect(response).to have_http_status(:not_found)
      expect(response_json['error']).to eq('Application not Found')
    end
  end

  describe 'GET #show' do
    it 'renders chat details when chat is found' do
      chat = FactoryBot.create(:chat, application: application)

      get :show, params: { application_token: application.token, number: chat.number }

      expect(response).to have_http_status(:ok)
      expect(response_json).to eq({ 'number' => chat.number, 'messages_count' => chat.messages_count })
      validate_id_and_timestamps_not_returned()
    end

    it 'renders error response when chat is not found' do
      get :show, params: { application_token: application.token, number: 999 }

      expect(response).to have_http_status(:not_found)
      expect(response_json['error']).to eq('Chat not Found')
    end
  end

  describe 'GET #index' do
    let!(:chats) { FactoryBot.create_list(:chat, 3, application: application) }
    let!(:other_chats) { FactoryBot.create_list(:chat, 2, application: other_application) }

    it 'renders a list of chats for the given application' do
      get :index, params: { application_token: application.token }

      expect(response).to have_http_status(:ok)
      expect(response_json.count).to eq(3)
    end

    it 'renders the correct number of chats for the given page_size' do
      get :index, params: { application_token: application.token , page_size: 1}

      expect(response).to have_http_status(:ok)
      expect(response_json.count).to eq(1)
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

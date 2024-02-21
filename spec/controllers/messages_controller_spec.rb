require 'rails_helper'

RSpec.describe MessagesController, type: :controller do
  let(:chat) { FactoryBot.create(:chat) }
  let(:valid_params) do
    {
      chat_number: chat.number,
      application_token: chat.application.token,
      message: { body: 'Test Body' }
    }
  end

  describe 'POST create' do
    before do
      allow(SecureRandom).to receive(:uuid).and_return('fake_uuid')
      allow($redis).to receive(:incr).and_return(1)
      allow($redis).to receive(:lpush).and_return(Rails.configuration.messages_batch_size + 1)
      allow(CreateMessagesJob).to receive(:perform_async)
    end

    context 'with valid parameters' do
      it 'adds new message data correctly to the queue' do
        post :create, params: valid_params
        expect(response).to have_http_status(:created)
        expect(response_json['number']).to eq(1)
        expect(response_json['body']).to eq('Test Body')
        validate_id_and_timestamps_not_returned

        expect($redis).to have_received(:incr).with(
          "#{Rails.configuration.redis_messages_number_key_prefix}_#{chat.id}"
        )

        expect(Message.count).to eq(0)

        expect($redis).to have_received(:lpush).with(
          'messages',
          {
            'number' => 1,
            'chat_id' => chat.id,
            'body' => 'Test Body'
          }.to_json
        )
      end
    end

    context 'with invalid parameters' do
      it 'returns bad request status' do
        post :create, params: {
          chat_number: chat.number,
          application_token: chat.application.token,
          message: { body: '' }
        }
        expect(response).to have_http_status(:bad_request)
        expect(Message.count).to eq(0)
      end

      it 'enqueues a job when queue size is greater than or equal to batch size' do
        allow($redis).to receive(:lpush).and_return(Rails.configuration.messages_batch_size)

        post :create, params: valid_params

        expect(CreateMessagesJob).to have_received(:perform_async).with('fake_uuid')
      end

      it 'doesnt enqueue a job when queue size is less than to batch size' do
        allow($redis).to receive(:lpush).and_return(Rails.configuration.messages_batch_size - 1)

        post :create, params: valid_params

        expect(CreateMessagesJob).to_not have_received(:perform_async)
      end

      it 'renders error response when chat is not found' do
        post :create, params: {
          chat_number: chat.number,
          application_token: 'invalid token',
          message: { body: '' }
        }

        expect(response).to have_http_status(:not_found)
        expect(response_json['error']).to eq('Chat not Found')
      end
    end
  end

  describe 'GET show' do
    context 'when the message exists' do
      let(:message) { FactoryBot.create(:message, chat: chat) }

      it 'returns the message details' do
        get :show,
            params: { chat_number: chat.number, application_token: chat.application.token, number: message.number }
        expect(response).to have_http_status(:ok)
        expect(response_json['number']).to eq(message.number)
        expect(response_json['name']).to eq(message.body)
        validate_id_and_timestamps_not_returned
      end
    end

    context 'when the message does not exist' do
      it 'returns not found status' do
        get :show, params: { chat_number: chat.number, application_token: chat.application.token, number: 123 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET index' do
    context 'when messages exist' do
      let!(:messages) { FactoryBot.create_list(:message, 3, chat: chat) }

      it 'returns a list of messages' do
        get :index, params: { chat_number: chat.number, application_token: chat.application.token }
        expect(response).to have_http_status(:ok)
        expect(response_json.size).to eq(3)
      end

      it 'renders the correct number of messages for the given page_size' do
        get :index, params: { chat_number: chat.number, application_token: chat.application.token, page_size: 1 }

        expect(response).to have_http_status(:ok)
        expect(response_json.count).to eq(1)
      end
    end
  end

  describe 'GET search' do
    let!(:messages) { FactoryBot.create_list(:message, 3, chat: chat) }

    before do
      allow(Message).to receive(:search).and_return(messages)
    end

    context 'when messages exist' do
      it 'returns a list of messages' do
        get :search, params: { chat_number: chat.number, application_token: chat.application.token, body: 'test' }
        expect(response).to have_http_status(:ok)
        expect(response_json.size).to eq(3)
      end
    end

    context 'when body not sent' do
      it 'returns a bad request' do
        get :search, params: { chat_number: chat.number, application_token: chat.application.token }
        expect(response).to have_http_status(:bad_request)
        expect(response_json['error']).to eq("Query param 'body' is required for search")
      end
    end
  end

  describe 'PATCH update' do
    let(:updated_body) { 'Updated Body' }
    context 'when the message exists' do
      let!(:message) { FactoryBot.create(:message, chat: chat) }

      it 'updates the message' do
        patch :update,
              params: { chat_number: chat.number, application_token: chat.application.token, number: message.number,
                        message: { body: updated_body } }
        expect(response).to have_http_status(:ok)
        expect(message.reload.body).to eq(updated_body)
      end
    end

    context 'when the message does not exist' do
      it 'returns not found status' do
        patch :update,
              params: { chat_number: chat.number, application_token: chat.application.token, number: 123,
                        message: { body: updated_body } }
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with invalid parameters' do
      let!(:message) { FactoryBot.create(:message, chat: chat) }

      it 'returns bad request status' do
        patch :update,
              params: { chat_number: chat.number, application_token: chat.application.token, number: message.number,
                        message: { body: '' } }
        expect(response).to have_http_status(:bad_request)
        expect(message.reload.body).not_to eq('')
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

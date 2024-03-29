class MessagesController < ApplicationController
  include PaginationConcern

  def create
    chat = Chat.joins(:application).where(
      number: params[:chat_number],
      application: { token: params[:application_token] }
    ).select('id').first
    return render(json: { "error": 'Chat not Found' }, status: :not_found) unless chat

    message_number = $redis.incr(
      "#{Rails.configuration.redis_messages_number_key_prefix}_#{chat.id}"
    )
    message = Message.new(message_params)
    message.number = message_number
    message.chat = chat

    if message.valid?
      queue_size = $redis.lpush('messages', {
        'number' => message_number,
        'chat_id' => chat.id,
        'body' => message.body
      }.to_json)
      CreateMessagesJob.perform_async(SecureRandom.uuid) if queue_size >= Rails.configuration.messages_batch_size
      render json: MessageRepresenter.new(message).as_json, status: :created
    else
      render json: message.errors, status: :bad_request
    end
  end

  def show
    message = Message.includes(:chat, chat: [:application]).where(
      number: params[:number],
      application: { token: params[:application_token] },
      chat: { number: params[:chat_number] }
    ).pluck(
      'messages.number', 'messages.body'
    ).map { |number, body| { number: number, name: body } }

    if message.empty?
      render json: { "error": 'Message not Found' }, status: :not_found
    else
      render json: message[0]
    end
  end

  def index
    messages = Message.includes(:chat, chat: [:application]).where(
      application: { token: params[:application_token] },
      chat: { number: params[:chat_number] }
    ).order(number: :desc)
    messages = paginate(messages).pluck(
      'messages.number', 'messages.body'
    ).map { |number, body| { number: number, name: body } }
    render json: messages
  end

  def search
    chat = Chat.joins(:application).where(
      number: params[:chat_number],
      application: { token: params[:application_token] }
    ).first
    return render(json: { "error": 'Chat not Found' }, status: :not_found) unless chat

    validate_body_param
    page_number, page_size = get_pagination_params
    messages = Message.search(params[:body], chat.id, page_number, page_size)
    render json: MessageRepresenter.new(messages).as_json
  end

  def update
    message = Message.includes(:chat, chat: [:application]).where(
      number: params[:number],
      application: { token: params[:application_token] },
      chat: { number: params[:chat_number] }
    ).first
    return render(json: { "error": 'Message not Found' }, status: :not_found) unless message

    if message.update(message_params)
      render json: MessageRepresenter.new(message).as_json
    else
      render json: { errors: message.errors }, status: :bad_request
    end
  end

  private

  def message_params
    params.require(:message).permit(:body)
  end

  def validate_body_param
    return unless params[:body].blank?

    raise Exceptions::MissingQueryParameterError, "Query param 'body' is required for search"
  end

  rescue_from Exceptions::MissingQueryParameterError do |e|
    render json: { error: e.to_s }, status: :bad_request
  end
end

class MessagesController < ApplicationController
	include PaginationConcern

	def create
		chat = Chat.joins(:application).where(
			number: params[:chat_number],
			application:{ token: params[:application_token] }
		).first
		return render(json: "Chat not Found", status: 404) unless chat

		redis = Redis.new(host: "redis", port: 6379)
		message_number = redis.incr("application_#{params[:application_token]}_chat_#{chat.number}_messages_count")
		message = Message.new(message_params)
        message.number = message_number
        message.chat = chat

		if message.valid?
			queue_size = redis.lpush("messages", {
				"number"=>message_number,
				"chat_id"=>chat.id,
				"body"=>message.body
			}.to_json)
			if queue_size >= Rails.configuration.messages_batch_size
				CreateMessagesJob.perform_async(SecureRandom.uuid)
			end
			render json: MessageRepresenter.new(message).as_json, status: :created
		else
			render json: message.errors, status: :bad_request
		end
	end

	def show
		message = Message.includes(:chat, :chat => [:application]).where(
			number: params[:number],
			application:{ token: params[:application_token] },
			chat: {number: params[:chat_number]}
		).pluck(
			'messages.number', 'messages.body'
		).map { |number, body| {id: number, name: body}}
		puts message
		unless message.empty?
			render json: message[0]
		else
			render json: "Message not Found", status: 404
		end
	end

	def index
		messages = Message.includes(:chat, :chat => [:application]).where(
			application:{ token: params[:application_token] },
			chat: {number: params[:chat_number]}
		).order(number: :desc).pluck(
			'messages.number', 'messages.body'
		).map { |number, body| {id: number, name: body}}
		render json: messages
	end

	def search
		chat = Chat.joins(:application).where(
			number: params[:chat_number],
			application:{ token: params[:application_token] }
		).first
		return render(json: "Chat not Found", status: 404) unless chat
		validate_body_param()
		page_number, page_size = get_pagination_params()
		messages = Message.search(params[:body], chat.id, page_number, page_size)
		render json: MessageRepresenter.new(messages).as_json
	end

	def update
		message = Message.includes(:chat, :chat => [:application]).where(
			number: params[:number],
			application:{ token: params[:application_token] },
			chat: {number: params[:chat_number]}
		).first
		return render(json: "Message not Found", status: 404) unless message
	
		if message.update(message_params)
		  render json: MessageRepresenter.new(message).as_json
		else
		  render json: { errors: message.errors }, status: :unprocessable_entity
		end
	end

    private
    def message_params
        params.require(:message).permit(:body)
    end
	
	def validate_body_param()
		if params[:body].blank?
			raise Exceptions::MissingQueryParameterError.new(
				"Query param 'body' is required for search"
			)
		end		
	end

	rescue_from Exceptions::MissingQueryParameterError do |e|
		render json: { error: e.to_s }, :status => :bad_request
	end
end

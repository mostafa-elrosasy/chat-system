class MessagesController < ApplicationController
	DEFAULT_SEARCH_PAGE_SIZE = 10
	MAX_SEARCH_PAGE_SIZE = 100
    
	def create
		chat = Chat.joins(:application).where(
			number: params[:chat_number],
			application:{ token: params[:application_token] }
		).first
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
			render json: message, status: :created
		else
			render json: message.errors, status: :bad_request
		end
	end

	def show
		chat = Chat.joins(:application).where(
			number: params[:chat_number],
			application:{ token: params[:application_token] }
		).first
        message = Message.find_by(chat: chat, number: params[:number])

		if message
			render json:message
		else
			render json: "Message not Found", status: 404
		end
	end

	def search
		chat = Chat.joins(:application).where(
			number: params[:chat_number],
			application:{ token: params[:application_token] }
		).first
		search_text, page_number, page_size = get_search_params_if_valid()
		puts get_search_params_if_valid
		render json: Message.search(search_text, chat.id, page_number, page_size)
	end

	
    private
    def message_params
        params.require(:message).permit(:body)
    end
	
	def get_search_params_if_valid()
		if params[:body].blank?
			raise Exceptions::MissingQueryParameterError.new(
				"Query param 'body' is required for search"
			)
		end
		page_size = params.fetch(:page_size, DEFAULT_SEARCH_PAGE_SIZE).to_i
		page_size = DEFAULT_SEARCH_PAGE_SIZE if page_size <= 0 
		page_size = [page_size, MAX_SEARCH_PAGE_SIZE].min
		page_number = params.fetch(:page_number, 1).to_i
		page_number = 1 if page_number < 1
		return params[:body], page_number, page_size
	end

	rescue_from Exceptions::MissingQueryParameterError do |e|
		render json: { error: e.to_s }, :status => :bad_request
	end
end

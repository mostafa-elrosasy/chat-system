class MessagesController < ApplicationController
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

		if message.save
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

    private
    def message_params
        params.require(:message).permit(:body)
    end
end

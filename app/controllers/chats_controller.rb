class ChatsController < ApplicationController
	def create
		application = Application.find_by(token: params[:application_token])
		redis = Redis.new(host: "redis", port: 6379)
		chat_number = redis.incr("application_#{params[:application_token]}_chats_count")
		chat = Chat.new(number: chat_number, messages_count: 0, application: application)

		if chat.save
			render json: chat, status: :created
		else
			render json: chat.errors, status: :bad_request
		end
	end

	def show
		chat = Chat.joins(:application).where(
			number: params[:number],
			application:{ token: params[:application_token] }
		).first
		if chat
			render json:chat
		else
			render json: "Chat not Found", status: 404
		end
	end
end

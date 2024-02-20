require 'securerandom'

class ChatsController < ApplicationController
	include PaginationConcern

	def create
		application = Application.where(
			token: params[:application_token]
		).select("id").first
		return render(json: "Application not Found", status: 404) unless application

		chat_number = $redis.incr(
			"#{Rails.configuration.redis_chats_number_key_prefix}_#{application.id}"
		)
		chat = Chat.new(number: chat_number, messages_count: 0, application: application)

		if chat.valid?
			queue_size = $redis.lpush("chats", {
				"number"=>chat_number,
				"messages_count"=>0,
				"application_id"=>application.id
			}.to_json)
			if queue_size >= Rails.configuration.chats_batch_size
				CreateChatsJob.perform_async(SecureRandom.uuid)
			end
			render json: ChatRepresenter.new(chat).as_json, status: :created
		else
			render json: chat.errors, status: :bad_request
		end
	end

	def show
		chat = Chat.joins(:application).where(
			number: params[:number],
			application:{ token: params[:application_token] }
		).pluck(
			'chats.number', 'chats.messages_count'
		).map { |number, messages_count| {number: number, messages_count: messages_count}}

		unless chat.empty?
			render json: chat[0]
		else
			render json: "Chat not Found", status: 404
		end
	end

	def index
		chats = Chat.joins(:application).where(
			application:{ token: params[:application_token] }
		)
		chats = paginate(chats) .pluck(
			'chats.number', 'chats.messages_count'
		).map { |number, messages_count| {number: number, messages_count: messages_count}}
		render json: chats
	end
end

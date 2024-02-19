require 'sidekiq'
require 'json'

class CreateMessagesJob
  include Sidekiq::Job
  sidekiq_options retry: 1

  def perform(back_up_queue_id)
    redis = Redis.new(host: "redis", port: 6379)
    messages_data =  redis.lrange(back_up_queue_id, 0, -1)
    (Rails.configuration.messages_batch_size - messages_data.length).times do
      message_data = redis.lmove("messages", back_up_queue_id, :right, :left)
      break if message_data.nil?        
      messages_data.append(message_data)
    end
    messages_data = messages_data.map { |message_data| JSON.parse(message_data) }
    Message.insert_all(messages_data)
    index_messages(messages_data)
    redis.del(back_up_queue_id)
  end

  def index_messages(messages_data)
    conditions = []
    messages_data.each do |message_data|
      conditions << "(number = #{message_data["number"]} AND chat_id = #{message_data["chat_id"]})"
    end
    query = conditions.join(' OR ')
    begin
      Message.import(query: -> { where(query) })
    rescue ArgumentError 
      Message.import(query: -> { where(query) }, force: true)
    end
  end
end

require 'sidekiq'
require 'json'

class CreateChatsJob
  include Sidekiq::Job
  sidekiq_options retry: 3

  def perform(back_up_queue_id)
    chats_data = $redis.lrange(back_up_queue_id, 0, -1)
    (Rails.configuration.chats_batch_size - chats_data.length).times do
      chat_data = $redis.lmove('chats', back_up_queue_id, :right, :left)
      break if chat_data.nil?

      chats_data.append(chat_data)
    end
    chats_data = chats_data.map { |chat_data| JSON.parse(chat_data) }
    Chat.insert_all(chats_data)
    $redis.del(back_up_queue_id)
  end
end

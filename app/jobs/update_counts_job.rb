require 'sidekiq'

class UpdateCountsJob
  include Sidekiq::Job
  sidekiq_options retry: 1

  def perform
    chats_count_subquery = <<-SQL
      IFNULL(
        (SELECT COUNT(id)
        FROM chats
        WHERE chats.application_id = applications.id
        GROUP BY application_id), 0)
    SQL
    Application.in_batches(of: 1000).update_all("chats_count = #{chats_count_subquery}")

    messages_count_subquery = <<-SQL
      IFNULL(
        (SELECT COUNT(id)
        FROM messages
        WHERE messages.chat_id = chats.id
        GROUP BY chat_id), 0)
    SQL
    Chat.in_batches(of: 1000).update_all("messages_count = #{messages_count_subquery}")
  end
end

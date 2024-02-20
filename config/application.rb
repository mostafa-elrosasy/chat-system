require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module App
  class Application < Rails::Application
    config.api_only = true
    config.debug_exception_response_format = :api
    config.active_job.queue_adapter = :sidekiq
    config.load_defaults 7.1


    config.autoload_lib(ignore: %w(assets tasks))

    config.redis_chats_number_key_prefix = "chats_number_application"
    config.redis_messages_number_key_prefix = "messages_number_chat"
    config.chats_batch_size = 3
    config.messages_batch_size = 3
  end
end

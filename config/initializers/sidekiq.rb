require 'json'

Sidekiq.configure_server do |config|
  config.redis = { url: 'redis://redis:6379/1' }
  schedule_file = "config/schedule.yml"
  if File.exists?(schedule_file)
    Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: 'redis://redis:6379/1' }
end

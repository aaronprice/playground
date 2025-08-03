# Configure Sidekiq
Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://redis:6379/0') }

  # Set log level to WARN in test environment to suppress INFO messages
  if Rails.env.test?
    config.logger.level = Logger::WARN
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://redis:6379/0') }

  # Set log level to WARN in test environment to suppress INFO messages
  if Rails.env.test?
    config.logger.level = Logger::WARN
  end
end
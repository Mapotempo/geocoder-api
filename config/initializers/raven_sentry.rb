if ENV['SENTRY_DSN'] || ENV['RAVEN_DSN']
  Raven.configure { |config|
    config.dsn = ENV['SENTRY_DSN'] || ENV['RAVEN_DSN']
  }
end
# Raven.tags_context release: GeocoderWrapper.release

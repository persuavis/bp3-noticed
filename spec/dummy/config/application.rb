# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Require bp3 dependencies
require 'bp3/core'
require 'bp3/action_dispatch'

# Require noticed and bp3-noticed gem
require 'noticed'
require 'bp3/noticed'

# Explicitly load the railtie now that Rails is available
require 'bp3/noticed/railtie'

module Dummy
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Set the root path for the dummy application to spec/
    # This is intentional - it allows Rails to find config/database.yml at spec/config/database.yml
    config.root = File.expand_path('../..', __dir__)

    # Configuration for the application, engines, and railties goes here.
    config.eager_load = false

    # Don't generate system test files.
    config.generators.system_tests = nil

    # Use test adapter for ActiveJob
    config.active_job.queue_adapter = :test

    # Disable some unnecessary features for testing
    config.action_mailer.show_previews = false
    config.action_controller.allow_forgery_protection = false

    # Use in-memory cache store for testing
    config.cache_store = :memory_store
  end
end

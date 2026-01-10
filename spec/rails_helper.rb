# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'

# Set Rails root before loading the application
ENV['RAILS_ROOT'] = File.expand_path('dummy', __dir__)

# IMPORTANT: Load the gem BEFORE Rails initializes so the railtie can register
# This is already done in dummy/config/application.rb, but we're being explicit here

# Load the dummy Rails application (this will also load bp3/noticed via application.rb)
require File.expand_path('dummy/config/environment', __dir__)

# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?

# We don't need rspec-rails for these tests - just basic rspec
require 'rspec'

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories.
Dir[File.join(__dir__, 'support', '**', '*.rb')].each { |f| require f }

RSpec.configure do |config|
  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Enable example status persistence
  config.example_status_persistence_file_path = '.rspec_status'
end

# frozen_string_literal: true

# NOTE: This spec_helper is for unit tests that don't need Rails.
# For integration tests that need Rails (like railtie tests), use rails_helper.rb instead.
# Do NOT require 'bp3/noticed' here, as that would load the railtie before Rails is available.

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

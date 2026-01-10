# Railtie Integration Testing

This directory contains integration tests for the `Bp3::Noticed::Railtie`.

## Setup

We've created a minimal dummy Rails application in `spec/dummy/` that:

1. Loads Rails 8.1+
2. Loads the `noticed` gem
3. Loads the `bp3-noticed` gem
4. Initializes the Rails application, which triggers the railtie

## Structure

```
spec/
├── dummy/                    # Minimal Rails app for testing
│   └── config/
│       ├── application.rb    # Rails application configuration
│       ├── boot.rb          # Bundler setup
│       ├── database.yml     # SQLite in-memory database
│       ├── environment.rb   # Rails initialization
│       └── environments/
│           └── test.rb      # Test environment config
├── integration/
│   ├── README.md            # This file
│   └── railtie_spec.rb      # Railtie integration tests
└── rails_helper.rb          # Rails test setup

```

## Running the Tests

```bash
# Run all railtie integration tests
bundle exec rspec spec/integration/railtie_spec.rb

# Run with documentation format
bundle exec rspec spec/integration/railtie_spec.rb --format documentation
```

## What the Tests Verify

The railtie integration tests verify that `Bp3::Noticed::Railtie` correctly:

1. **Modifies `Noticed::Event`** - Includes BP3::Core modules (Rqid, Sqnr, Tenantable, Ransackable)
2. **Modifies `Noticed::Notification`** - Includes BP3::Core modules
3. **Modifies `Noticed::ApplicationJob`** - Includes SystemLogs, CommonIncludes, JobIncludes
4. **Modifies `Noticed::EventJob`** - Prepends PrependPerform, includes SystemLogs
5. **Modifies `Noticed::DeliveryMethod`** - Prepends PrependPerform, includes SystemLogs
6. **Modifies delivery method classes** - Each delivery method class gets PrependPerform and SystemLogs

## Limitations

These tests require a full Rails environment with all bp3-core dependencies available. In a real BP3 application, all dependencies (bp3-core, bp3-action_dispatch) will be present and the railtie will function correctly.

For isolated gem testing without the full BP3 stack, you would need to:
- Mock or stub the Bp3::Core modules
- Mock the Bp3::ActionDispatch.site_class method
- Or run the tests in a full BP3 application environment

## Dependencies

The dummy Rails app requires:
- rails >= 8.1
- rspec-rails >= 7.0
- sqlite3 >= 2.0
- All dependencies from bp3-noticed.gemspec

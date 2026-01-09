# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

bp3-noticed is a Ruby gem that adapts the `noticed` notification library for BP3 (Black Phoebe 3), a multi-site multi-tenant Rails application. It integrates BP3's core functionality (Rqid, Sqnr, Tenantable, Ransackable) with the `noticed` gem to ensure notifications work correctly within BP3's multi-tenant architecture.

## Commands

### Testing and Linting
- `rake` or `rake default` - Run both RSpec tests and RuboCop linting
- `rake spec` - Run RSpec tests only
- `rake rubocop` - Run RuboCop linting only
- `rspec spec/path/to/specific_spec.rb` - Run a single test file
- `rspec spec/path/to/specific_spec.rb:42` - Run a specific test at line 42

### Development
- `bin/setup` - Install dependencies after checking out the repo
- `bin/console` - Interactive prompt for experimentation
- `rake install` - Install gem onto local machine
- `rake release` - Release new version (updates version, creates git tag, pushes to rubygems.org)

## Architecture

### Core Integration Pattern

This gem uses a **prepend-and-include pattern** to inject BP3 functionality into jobs:

1. **CommonIncludes** - Shared functionality for both ActiveJob and Que jobs
   - Provides global request state management
   - Site resolution and tenant context preservation
   - Implements `run(...)` method that calls `perform(...)`

2. **JobIncludes** - For ActiveJob jobs (include in ApplicationJob)
   - Adds `enqueue` override to inject state into job arguments
   - Provides convenience methods: `run_now`, `run_soon`, `run_later`

3. **QueIncludes** - For Que jobs (include in Que::Job base class)
   - Similar to JobIncludes but adapted for Que's API
   - Includes debug logging when `BP_DEBUG=quejobs`

4. **PrependPerform** - Must be prepended in every custom job class
   - Wraps `perform` method to set/clear global request state
   - Removes state from args/kwargs before calling super
   - Logs job execution and failures via SystemLogs
   - Handles ArgumentError fallback for jobs relying on run_attrs

### Railtie Configuration

The `Bp3::Noticed::Railtie` (lib/bp3/noticed/railtie.rb:22-123) runs after Rails initialization to:
- Preload and monkey-patch `Noticed::Event`, `Noticed::Notification`, `Noticed::ApplicationJob`, `Noticed::EventJob`, and `Noticed::DeliveryMethod` classes
- Mix in BP3::Core modules (Rqid, Sqnr, Tenantable, Ransackable) to Noticed models
- Configure tenancy and sequencing for ordering
- Override `recipient_attributes_for` to inject global scope (site_id, tenant_id, workspace_id)
- Apply PrependPerform and SystemLogs to all delivery method classes

### Global Request State Management

Jobs running in background workers need access to the current site, tenant, and workspace context. This is achieved by:
1. Capturing `GlobalRequestState.to_hash` when enqueuing
2. Passing state as a job argument (not kwarg)
3. Restoring state via `GlobalRequestState.from_hash(state)` in PrependPerform
4. Clearing state in ensure block after job completes

This pattern ensures multi-tenant isolation is maintained across background job boundaries.

## Integration Requirements

When using this gem in a BP3 application:

**For ActiveJob:**
```ruby
# In ApplicationJob
include Bp3::Noticed::CommonIncludes
include Bp3::Noticed::JobIncludes

# In every custom job class
prepend Bp3::Noticed::PrependPerform
```

**For Que Jobs (if used):**
```ruby
# In Que base job class
include Bp3::Noticed::CommonIncludes
include Bp3::Noticed::QueIncludes

# In every custom job class
prepend Bp3::Noticed::PrependPerform
```

**Important:** Do NOT change `Noticed.parent_class` - this gem handles the necessary modifications.

## RuboCop Configuration

- Target Ruby: 3.2.2+ (gem requires >= 3.2.0)
- Plugins: rubocop-rake, rubocop-rspec
- NewCops enabled
- Style/Documentation disabled
- Special allowances for lib/bp3/**/railtie.rb (ConstantDefinitionInBlock, Lint/Void)
- Custom metrics: AbcSize: 26, BlockLength: 66, MethodLength: 15, ModuleLength: 150

## Dependencies

Core dependencies:
- `activesupport ~> 8.1`
- `noticed >= 2.2` - The upstream notification library being adapted
- `bp3-core >= 0.1` - Provides Rqid, Sqnr, Tenantable, Ransackable, SystemLogs
- `bp3-action_dispatch >= 0.1` - Provides site_class
- `apnotic ~> 1` - Apple Push Notification support

Note: FCM (Firebase Cloud Messaging) delivery method is disabled until `googleauth` supports newer gem versions.

## Repository Structure

```
lib/
├── bp3-noticed.rb              # Main entry point
└── bp3/
    └── noticed/
        ├── common_includes.rb   # Shared job functionality
        ├── job_includes.rb      # ActiveJob-specific
        ├── que_includes.rb      # Que-specific
        ├── prepend_perform.rb   # Performance wrapper
        ├── railtie.rb          # Rails integration & monkey patches
        └── version.rb          # Gem version
```

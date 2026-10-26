# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

bp3-noticed adapts the `noticed` (2.x) notification library for BP3 (persuavis/black_phoebe_3), a
multi-site multi-tenant Rails application. It makes noticed's events and notifications BP3 records, and
gives background jobs, noticed's and the application's own, the caller's request state.

## Commands

The gems run on Ruby 3.4.6 (`.ruby-version`). Prefix commands with `~/.rvm/bin/rvm 3.4.6 do` when the
shell is not already on it; a missing `rspec` means the wrong Ruby, not a missing bundle.

- `bundle exec rake` - specs and RuboCop (the default task)
- `bundle exec rspec spec/path/to/file_spec.rb[:LINE]` - one file or example
- `bundle exec rubocop` / `bundle exec rubocop -a`
- `bin/setup`, `bin/console`, `rake install`

## Architecture

### Job modules

**CommonIncludes** (`common_includes.rb`), for any job
- `global_request_state_class` (class and instance): `Bp3::Core::Rqid.global_request_state_class`
- `run(...)` calls `perform(...)`
- `set_global_request_state` restores the state from the job's `state` argument, then makes sure there is a
  current site: `ensure_site` looks up `sites_site_id`/`site_id` in the job's arguments, else falls back to
  the root site or the first site (`Bp3::ActionDispatch.site_class`)

**JobIncludes** (`job_includes.rb`), for ActiveJob
- `enqueue` appends `{ 'state' => GlobalRequestState.to_hash }` to the job's positional arguments
- `run_now` (`perform_later`, never `perform_now`), `run_soon` (1 minute), `run_later` (1 hour)
- `run_attrs(key)` searches the arguments for a key

**PrependPerform** (`prepend_perform.rb`), prepended to each job class
- sets the request state, strips the `state` entry from args and kwargs, calls `super` (retrying `super()`
  with no arguments on `ArgumentError`, for jobs that read `run_attrs`), logs finished or failed through
  `log_info`/`log_exception`, records an event through `add_event`, and clears the state in `ensure`
- `prepend_add_event`, `prepend_log_info` and `prepend_log_exception` call the job's own method when it has
  one and otherwise warn to the Rails log; override them in a job class to change that

### Railtie

`lib/bp3/noticed/railtie.rb` runs in `config.to_prepare`, not `after_initialize`, so the reopening is
repeated after every code reload. It is only defined when `Rails` is. It reopens:

- `Noticed::Event`: Rqid, Sqnr, Tenantable, Ransackable, `configure_tenancy`, `use_sqnr_for_ordering`.
  `recipient_attributes_for` merges in the current site, tenant and workspace ids, because notifications
  are bulk-inserted and skip Tenantable's callbacks
- `Noticed::Notification`: the same plus Displayable
- `Noticed::ApplicationJob`: SystemLogs, CommonIncludes, JobIncludes, `retry_on ActiveRecord::Deadlocked`
- `Noticed::EventJob`, `Noticed::DeliveryMethod` and each class named in `NOTICED_DELIVERY_METHODS` that
  exists: prepend PrependPerform, include SystemLogs. Fcm is left out until `googleauth` supports newer gems

Do not change `Noticed.parent_class`; the Railtie does what is needed.

### In the application

black_phoebe_3 wraps these modules in its own `app/jobs/concerns/` (`common_includes.rb`,
`job_includes.rb`, `prepend_perform.rb`), and `ApplicationJob` declares the retries.
Changes to the order or behavior of `PrependPerform` affect every job there; read those concerns before
changing it.

## Testing

`spec/rails_helper.rb` boots a minimal Rails app (`spec/dummy`, sqlite3) so the Railtie can run;
`spec/spec_helper.rb` must not require `bp3/noticed`, or the Railtie loads before Rails. The Railtie spec is
`spec/integration/bp3/noticed/railtie_spec.rb` (see `spec/integration/README.md`).

## Dependencies

- `activesupport ~> 8.1`, `noticed >= 2.2`, `apnotic ~> 1` (iOS push)
- `bp3-core >= 0.1` (Rqid, Sqnr, Tenantable, Ransackable, Displayable, SystemLogs)
- `bp3-action_dispatch >= 0.1` (`site_class`)
- Development: rails, rspec-rails, sqlite3, rubocop-rails, rubocop-rspec_rails

## Code Style

- RuboCop (`.rubocop.yml`): target Ruby 3.2.2, NewCops, rubocop-rake, rubocop-rspec, rubocop-rails and
  rubocop-rspec_rails; AbcSize 26, MethodLength 15, BlockLength 66, ModuleLength 150;
  `Lint/ConstantDefinitionInBlock` and `Lint/Void` are off for `lib/bp3/**/railtie.rb`
- Keep the "override in subclasses if needed" comments on the hook methods
- Every file starts with `# frozen_string_literal: true`
- American English; no trailing whitespace on any added or modified line

## Release

Bump `lib/bp3/noticed/version.rb` and add a `CHANGELOG.md` entry. `rake release` tags, pushes and
publishes to rubygems.org; leave releasing and committing to the user.

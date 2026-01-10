# frozen_string_literal: true

require 'active_support/concern'
require_relative 'noticed/common_includes'
require_relative 'noticed/job_includes'
require_relative 'noticed/que_includes'
require_relative 'noticed/prepend_perform'
require_relative 'noticed/version'

# NOTE: Do NOT require the railtie here!
# The railtie should be loaded by the Rails application AFTER Rails is loaded.
# See: https://guides.rubyonrails.org/engines.html#inside-an-engine

module Bp3
  module Noticed
  end
end

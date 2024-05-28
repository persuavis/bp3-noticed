# frozen_string_literal: true

require_relative 'noticed/version'
require_relative 'noticed/common_includes'
require_relative 'noticed/job_includes'
require_relative 'noticed/que_includes'
require_relative 'noticed/prepend_perform'
require_relative 'noticed/railtie'

module Bp3
  module Noticed
    class Error < StandardError; end
    # Your code goes here...
  end
end

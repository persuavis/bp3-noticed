# frozen_string_literal: true

module QueIncludes
  extend ActiveSupport::Concern

  class_methods do
    def enqueue(*args, **kwargs)
      if ENV.fetch('BP_DEBUG', nil) =~ /quejobs/
        Rails.logger.warn { "enqueue with #{args} and #{kwargs}" }
        Rails.logger.warn { GlobalRequestState.to_hash }
      end
      kwargs['state'] = GlobalRequestState.to_hash
      super(*args, **kwargs)
    end

    def perform_now(...)
      run(...)
    end

    def run_now(...)
      enqueue(...) # don't use perform_now, as it won't run in the background
    end

    def run_soon(*, **kwargs)
      kwargs[:job_options] ||= {}
      kwargs[:job_options][:run_at] ||= 1.minute.from_now
      enqueue(*, **kwargs)
    end

    def run_later(*, **kwargs)
      kwargs[:job_options] ||= {}
      kwargs[:job_options][:run_at] ||= 1.hour.from_now
      enqueue(*, **kwargs)
    end
  end

  # set the log level based on the job duration. elapsed is in seconds
  def log_level(elapsed)
    if elapsed > 5
      :warn
    elsif elapsed > 1
      :info
    else
      false # no need to log
    end
  end

  private

  def job_type
    'que'
  end

  def run_attrs(key)
    check(que_attrs, key) ||
      check(que_attrs[:args], key) ||
      check(que_attrs[:kwargs], key) ||
      check(args, key) ||
      check(kwargs, key)
  end
end

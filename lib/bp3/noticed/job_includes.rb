# frozen_string_literal: true

module JobIncludes
  extend ActiveSupport::Concern

  class_methods do
    def enqueue(...)
      new.enqueue(...)
    end

    def run_now(...)
      perform_later(...) # don't use perform_now, as it won't run in the background
    end

    def run_soon(...)
      set(wait: 1.minute).perform_later(...)
    end

    def run_later(...)
      set(wait: 1.hour).perform_later(...)
    end
  end

  def enqueue(*, **)
    # Add state to arguments, not kwargs
    # kwargs['state'] = GlobalRequestState.to_hash
    arguments << { 'state' => global_request_state_class.to_hash }
    super
  end

  private

  def job_type
    'job'
  end

  def run_attrs(key)
    check(arguments, key)
  end

  def check(hash_or_array, key)
    return nil if hash_or_array.blank?

    if hash_or_array.is_a?(Array)
      hash_or_array.each do |obj|
        value = check(obj, key)
        return value if value
      end
      nil
    elsif hash_or_array.is_a?(Hash)
      hash_or_array[key.to_s] || hash_or_array[key.to_sym]
    end
  end

  def site
    global_request_state_class.current_site
  end

  def job_key
    self.class.name.underscore
  end
end

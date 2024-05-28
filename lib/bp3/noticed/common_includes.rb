# frozen_string_literal: true

module CommonIncludes
  extend ActiveSupport::Concern

  included do
    attr_reader :args, :kwargs
  end

  class_methods do
    def global_request_state_class
      Bp3::Core::Rqid.global_request_state_class
    end
  end

  def global_request_state_class
    Bp3::Core::Rqid.global_request_state_class
  end

  def run(...)
    perform(...)
  end

  private

  def set_global_request_state
    global_request_state_class.from_hash(state)
    global_request_state_class.current_site ||= ensure_site
  end

  def state
    run_attrs :state
  end

  def ensure_site
    id = run_attrs(:sites_site_id) || run_attrs(:site_id)
    if id.present?
      site = site_class.find_by(id:)
      return site if site.present?

      message = "Unable to find site #{id}"
      include_log_error(key: 'prepend_state.ensure_site', message:)
    end

    site_class.root_site || site_class.first
  end

  def site_class
    Bp3::ActionDispatch.site_class
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

  def job_key
    self.class.name.underscore
  end
end

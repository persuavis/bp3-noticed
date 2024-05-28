# frozen_string_literal: true

module PrependPerform
  include CommonIncludes
  # rubocop:disable Metrics/MethodLength
  def perform(*args, **kwargs)
    @args = args
    @kwargs = kwargs
    set_global_request_state
    details = { args:, kwargs: }
    log = nil
    args = remove_state(args)
    kwargs = remove_state(kwargs)
    begin
      super(*args, **kwargs)
    rescue ArgumentError
      super() # in case super is relying on run_attrs
    end
    disposition = 'finished'
    log = prepend_log_info(key: "#{job_type}.#{disposition}.#{job_key}", message: "#{disposition} job_type", details:)
  rescue StandardError => e
    disposition = 'failed'
    log = prepend_log_exception(e, key: "#{job_type}.#{disposition}.#{job_key}", details:)
    raise e # to continue the normal job flow
  ensure
    prepend_add_event(eventable: log, disposition:)
    global_request_state_class.clear!
  end
  # rubocop:enable Metrics/MethodLength

  private

  def remove_state(obj)
    if obj.is_a?(Hash)
      obj.except(:state, 'state')
    elsif obj.is_a?(Array)
      obj.reject { |e| e.is_a?(Hash) && (e.key?(:state) || e.key?('state')) }
    else
      obj
    end
  end

  # override in subclasses if needed
  def prepend_add_event(eventable:, disposition:)
    return add_event(eventable:, disposition:) if respond_to?(:add_event, true)

    creator = global_request_state_class.current_login || global_request_state_class.current_visitor
    who = creator.nil? ? 'nil' : "#{creator.class.name}/#{creator.id}"
    did = disposition
    what = eventable.nil? ? 'nil' : "#{eventable.class.name}/#{eventable.id}"
    message = "Warning: #{self.class.name}#add_event: unable to add event #{who}/#{did}/#{what}"
    Rails.logger.warn { message }
    nil
  end

  # override in subclasses if needed
  def prepend_log_info(key:, message:, details: {})
    return log_info(key:, message:, details:) if respond_to?(:log_info, true)

    message = "Warning: #{self.class.name}#log_info: unable to log info #{key}/#{message}/#{details}"
    Rails.logger.warn { message }
    nil
  end

  # override in subclasses if needed
  def prepend_log_exception(exception, key:, details: {})
    return log_exception(exception, key:, details:) if respond_to?(:log_exception, true)

    message = "Warning: #{self.class.name}#log_exception: unable to log exception #{exception}/#{key}/#{details}"
    Rails.logger.warn { message }
    nil
  end

  def global_request_state_class
    Bp3::Core::Rqid.global_request_state_class
  end
end

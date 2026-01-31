# frozen_string_literal: true

module Bp3
  module Noticed
    NOTICED_DELIVERY_METHODS = %w[
      ActionCable
      ActionPushNative
      Discord
      Email
      Ios
      MicrosoftTeams
      Slack
      Test
      TwilioMessaging
      VonageSms
      Webhook
    ].freeze
    # TODO: add Fcm and add googleauth depency once googleauth supports newer gems

    # Define the Railtie only if Rails is already loaded
    # Use defined?(Rails) instead of defined?(Rails.env) or defined?(Rails::Railtie)
    # because those may not be accessible when this file is first loaded
    if defined?(Rails)
      class Railtie < Rails::Railtie
        # rubocop:disable Metrics/BlockLength
        initializer 'bp3.noticed.railtie.register' do |app|
          app.config.to_prepare do
            ::Noticed::Event # preload
            ::Noticed::Notification # preload
            ::Noticed::ApplicationJob # preload
            ::Noticed::EventJob # preload
            ::Noticed::DeliveryMethod # preload
            module ::Noticed
              class Event
                include Bp3::Core::Rqid
                include Bp3::Core::Sqnr
                include Bp3::Core::Tenantable
                include Bp3::Core::Ransackable

                configure_tenancy
                use_sqnr_for_ordering
                # has_paper_trail

                # override recipient_attributes_for to ensure that bulk inserts
                # (which skip callbacks) have site, tenant and workspace
                def recipient_attributes_for(recipient)
                  super.merge(global_scope)
                end

                private

                def global_scope
                  {
                    sites_site_id: global_site_id,
                    tenant_id: global_tenant_id,
                    workspaces_workspace_id: global_workspace_id
                  }
                end

                def global_site_id
                  global_request_state_class.current_site_id
                end

                def global_tenant_id
                  global_request_state_class.current_tenant_id
                end

                def global_workspace_id
                  global_request_state_class.current_workspace_id
                end

                def global_request_state_class
                  Bp3::Core::Rqid.global_request_state_class
                end
              end

              class Notification
                include Bp3::Core::Rqid
                include Bp3::Core::Sqnr
                include Bp3::Core::Tenantable
                include Bp3::Core::Ransackable
                include Bp3::Core::Displayable

                configure_tenancy
                use_sqnr_for_ordering
                # has_paper_trail
              end

              class ApplicationJob
                # include Que::ActiveJob::JobExtensions
                include Bp3::Core::SystemLogs
                include Bp3::Noticed::CommonIncludes
                include Bp3::Noticed::JobIncludes

                # Automatically retry jobs that encountered a deadlock
                retry_on ActiveRecord::Deadlocked
              end

              class EventJob
                prepend Bp3::Noticed::PrependPerform
                include Bp3::Core::SystemLogs
              end

              class DeliveryMethod
                prepend Bp3::Noticed::PrependPerform
                include Bp3::Core::SystemLogs
              end

              NOTICED_DELIVERY_METHODS.each do |delivery_method|
                class_name = "::Noticed::DeliveryMethods::#{delivery_method}"
                klass = begin
                  class_name.constantize
                rescue StandardError
                  nil
                end
                next unless klass

                klass.prepend Bp3::Noticed::PrependPerform
                klass.include Bp3::Core::SystemLogs
              end
            end
          end
        end
        # rubocop:enable Metrics/BlockLength
      end
    end
  end
end

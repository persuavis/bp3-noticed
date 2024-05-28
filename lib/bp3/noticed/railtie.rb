# frozen_string_literal: true

# require 'rails/railtie'

module Bp3
  module Noticed
    if defined?(Rails.env)
      class Railtie < Rails::Railtie
        initializer 'bp3.noticed.railtie.register' do |app|
          app.config.after_initialize do
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

                configure_tenancy
                use_sqnr_for_ordering
                # has_paper_trail

                def recipient_attributes_for(recipient)
                  # TODO: determine why workspaces_workspace_id is not set, but tenant_id is
                  super.merge({ workspaces_workspace_id: global_workspace_id })
                end

                private

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

                configure_tenancy
                use_sqnr_for_ordering
                # has_paper_trail
              end

              class ApplicationJob
                # include Que::ActiveJob::JobExtensions
                include CommonIncludes
                include JobIncludes
                # include SystemLogs

                # Automatically retry jobs that encountered a deadlock
                retry_on ActiveRecord::Deadlocked
              end

              class EventJob
                prepend PrependPerform
              end

              class DeliveryMethod
                prepend PrependPerform
              end
            end
          end
        end
      end
    end
  end
end

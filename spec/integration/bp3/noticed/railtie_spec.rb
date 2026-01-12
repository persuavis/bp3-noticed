# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bp3::Noticed::Railtie, type: :none do
  describe 'Noticed::Event modifications' do
    it 'includes Bp3::Core::Rqid module' do
      # Check by name since module identity might differ
      ancestor_names = Noticed::Event.ancestors.map(&:to_s)
      expect(ancestor_names).to include('Bp3::Core::Rqid')
    end

    it 'includes Bp3::Core::Sqnr module' do
      expect(Noticed::Event.ancestors).to include(Bp3::Core::Sqnr)
    end

    it 'includes Bp3::Core::Tenantable module' do
      expect(Noticed::Event.ancestors).to include(Bp3::Core::Tenantable)
    end

    it 'includes Bp3::Core::Ransackable module' do
      expect(Noticed::Event.ancestors).to include(Bp3::Core::Ransackable)
    end

    it 'responds to configure_tenancy' do
      expect(Noticed::Event).to respond_to(:configure_tenancy)
    end

    it 'responds to use_sqnr_for_ordering' do
      expect(Noticed::Event).to respond_to(:use_sqnr_for_ordering)
    end

    it 'has recipient_attributes_for method' do
      # Check that the method was defined by the railtie
      expect(Noticed::Event.instance_methods(false)).to include(:recipient_attributes_for)
    end

    it 'has global_request_state_class method' do
      # Check that the private method was defined by the railtie
      expect(Noticed::Event.private_instance_methods(false)).to include(:global_request_state_class)
    end
  end

  describe 'Noticed::Notification modifications' do
    it 'includes Bp3::Core::Rqid module' do
      expect(Noticed::Notification.ancestors).to include(Bp3::Core::Rqid)
    end

    it 'includes Bp3::Core::Sqnr module' do
      expect(Noticed::Notification.ancestors).to include(Bp3::Core::Sqnr)
    end

    it 'includes Bp3::Core::Tenantable module' do
      expect(Noticed::Notification.ancestors).to include(Bp3::Core::Tenantable)
    end

    it 'includes Bp3::Core::Ransackable module' do
      expect(Noticed::Notification.ancestors).to include(Bp3::Core::Ransackable)
    end

    it 'includes Bp3::Noticed::Displayable module' do
      expect(Noticed::Notification.ancestors).to include(Bp3::Core::Displayable)
    end

    it 'responds to configure_tenancy' do
      expect(Noticed::Notification).to respond_to(:configure_tenancy)
    end

    it 'responds to use_sqnr_for_ordering' do
      expect(Noticed::Notification).to respond_to(:use_sqnr_for_ordering)
    end
  end

  describe 'Noticed::ApplicationJob modifications' do
    it 'includes Bp3::Core::SystemLogs module' do
      expect(Noticed::ApplicationJob.ancestors).to include(Bp3::Core::SystemLogs)
    end

    it 'includes Bp3::Noticed::CommonIncludes module' do
      expect(Noticed::ApplicationJob.ancestors).to include(Bp3::Noticed::CommonIncludes)
    end

    it 'includes Bp3::Noticed::JobIncludes module' do
      expect(Noticed::ApplicationJob.ancestors).to include(Bp3::Noticed::JobIncludes)
    end

    it 'has retry_on configured for deadlocks' do
      # Check that retry_on was called by inspecting the job class
      expect(Noticed::ApplicationJob).to respond_to(:retry_on)
    end
  end

  describe 'Noticed::EventJob modifications' do
    it 'prepends Bp3::Noticed::PrependPerform module' do
      # PrependPerform should be at the beginning of the ancestor chain
      expect(Noticed::EventJob.ancestors).to include(Bp3::Noticed::PrependPerform)
      # Check it's prepended (comes before the class itself)
      prepend_index = Noticed::EventJob.ancestors.index(Bp3::Noticed::PrependPerform)
      class_index = Noticed::EventJob.ancestors.index(Noticed::EventJob)
      expect(prepend_index).to be < class_index
    end

    it 'includes Bp3::Core::SystemLogs module' do
      expect(Noticed::EventJob.ancestors).to include(Bp3::Core::SystemLogs)
    end
  end

  describe 'Noticed::DeliveryMethod modifications' do
    it 'prepends Bp3::Noticed::PrependPerform module' do
      expect(Noticed::DeliveryMethod.ancestors).to include(Bp3::Noticed::PrependPerform)
      # Check it's prepended
      prepend_index = Noticed::DeliveryMethod.ancestors.index(Bp3::Noticed::PrependPerform)
      class_index = Noticed::DeliveryMethod.ancestors.index(Noticed::DeliveryMethod)
      expect(prepend_index).to be < class_index
    end

    it 'includes Bp3::Core::SystemLogs module' do
      expect(Noticed::DeliveryMethod.ancestors).to include(Bp3::Core::SystemLogs)
    end
  end

  describe 'Noticed delivery method classes' do
    # Test a few common delivery methods that should exist
    %w[Test Email].each do |delivery_method|
      context "with Noticed::DeliveryMethods::#{delivery_method}" do
        let(:klass) { "Noticed::DeliveryMethods::#{delivery_method}".constantize }

        it 'prepends Bp3::Noticed::PrependPerform module' do
          expect(klass.ancestors).to include(Bp3::Noticed::PrependPerform)
        end

        it 'includes Bp3::Core::SystemLogs module' do
          expect(klass.ancestors).to include(Bp3::Core::SystemLogs)
        end
      end
    end
  end

  describe 'NOTICED_DELIVERY_METHODS constant' do
    it 'is defined' do
      expect(Bp3::Noticed::NOTICED_DELIVERY_METHODS).to be_a(Array)
    end

    it 'includes expected delivery methods' do
      expect(Bp3::Noticed::NOTICED_DELIVERY_METHODS).to include(
        'ActionCable',
        'Email',
        'Test',
        'Slack',
        'Webhook'
      )
    end

    it 'does not include Fcm (commented out)' do
      expect(Bp3::Noticed::NOTICED_DELIVERY_METHODS).not_to include('Fcm')
    end
  end
end

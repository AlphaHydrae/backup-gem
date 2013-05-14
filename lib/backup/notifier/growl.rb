# encoding: utf-8
require 'growl'

module Backup
  module Notifier
    class Growl < Base

      ##
      # Application name ("backup" by default)
      # Tell something like your server name. Example: "Server1 Backup"
      attr_accessor :application

      ##
      # Make the notification sticky
      attr_accessor :sticky

      def initialize(model, &block)
        super(model)
        @application ||= 'backup'

        instance_eval(&block) if block_given?
      end

      private

      ##
      # Notify the user of the backup operation results.
      # `status` indicates one of the following:
      #
      # `:success`
      # : The backup completed successfully.
      # : Notification will be sent if `on_success` was set to `true`
      #
      # `:warning`
      # : The backup completed successfully, but warnings were logged
      # : Notification will be sent, including a copy of the current
      # : backup log, if `on_warning` was set to `true`
      #
      # `:failure`
      # : The backup operation failed.
      # : Notification will be sent, including the Exception which caused
      # : the failure, the Exception's backtrace, a copy of the current
      # : backup log and other information if `on_failure` was set to `true`
      #
      def notify!(status)
        name = case status
               when :success then 'Success'
               when :warning then 'Warning'
               when :failure then 'Failure'
               end
        message = "[Backup::%s] #{@model.label} (#{@model.trigger})" %name
        send_message(message)
      end

      def send_message(message)
        growl = Object.const_get :Growl
        notification = growl.new
        notification.message = message
        notification.name = application
        notification.sticky! if sticky
        notification.run if growl.installed?
      end

    end
  end
end

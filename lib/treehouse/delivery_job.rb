# frozen_string_literal: true

ActiveSupport.on_load(:active_job) do
  include ::Sidekiq::Worker::Options unless respond_to?(:sidekiq_options)
end

module Treehouse
  class DeliveryJob < ActionMailer::MailDeliveryJob
    sidekiq_options retry: ENV.fetch('TH_MAILER_SIDEKIQ_RETRY_LIMIT', '2').to_i
  end
end
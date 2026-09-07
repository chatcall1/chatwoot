class BotFlows::RetryDeliveryJob < ApplicationJob
  queue_as :high

  def perform(delivery_id, scheduled_at)
    delivery = BotFlowDelivery.find(delivery_id)
    message_id = nil

    delivery.with_lock do
      return unless delivery.retryable?
      return unless delivery.retry_scheduled_at&.iso8601(6) == scheduled_at

      delivery.message.update!(status: :sent, external_error: nil)
      delivery.update!(
        status: :enqueued,
        attempt_count: delivery.attempt_count + 1,
        last_attempt_at: Time.current,
        retry_scheduled_at: nil,
        last_error: nil
      )
      message_id = delivery.message_id
    end

    SendReplyJob.perform_later(message_id)
  end
end

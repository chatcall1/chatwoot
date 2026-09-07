class BotFlowListener < BaseListener
  def message_created(event)
    message = extract_message_and_account(event)[0]
    BotFlows::ProcessIncomingMessageJob.perform_later(message.id) if message.incoming?
  end

  def message_updated(event)
    message = extract_message_and_account(event)[0]
    delivery_id = message.content_attributes['bot_flow_delivery_id']
    return if delivery_id.blank?

    delivery = BotFlowDelivery.find_by(id: delivery_id, message_id: message.id)
    return unless delivery

    sync_delivery(delivery, message)
  end

  private

  def sync_delivery(delivery, message)
    if message.read?
      delivery.update!(status: :read)
    elsif message.delivered?
      delivery.update!(status: :delivered)
    elsif message.source_id.present?
      delivery.update!(status: :accepted)
    elsif message.failed?
      mark_failed(delivery, message)
    end
  end

  def mark_failed(delivery, message)
    delivery.with_lock do
      delivery.update!(status: :failed, last_error: message.external_error)
      return unless delivery.retryable? && delivery.retry_scheduled_at.blank?

      wait = [delivery.attempt_count**2, 15].min.minutes
      scheduled_at = Time.current + wait
      delivery.update!(retry_scheduled_at: scheduled_at)
      BotFlows::RetryDeliveryJob.set(wait: wait).perform_later(delivery.id, scheduled_at.iso8601(6))
    end
  end
end

class BotFlowDelivery < ApplicationRecord
  belongs_to :bot_flow_execution
  belongs_to :message, optional: true

  enum status: { pending: 0, enqueued: 1, accepted: 2, delivered: 3, read: 4, failed: 5 }

  validates :node_id, presence: true, uniqueness: { scope: :bot_flow_execution_id }

  def retryable?
    failed? && message&.source_id.blank? && BotFlows::DeliveryRetryPolicy.new(last_error).retryable?
  end

  def manually_retryable?
    retryable? && (retry_scheduled_at.blank? || retry_scheduled_at > 5.seconds.from_now)
  end
end

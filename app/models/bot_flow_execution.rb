class BotFlowExecution < ApplicationRecord
  belongs_to :bot_flow
  belongs_to :account
  belongs_to :inbox
  belongs_to :conversation
  belongs_to :contact
  belongs_to :trigger_message, class_name: 'Message'

  has_many :bot_flow_deliveries, dependent: :destroy

  enum status: { pending: 0, running: 1, completed: 2, failed: 3, awaiting_input: 4 }

  validates :trigger_message_id, uniqueness: true
  validates :trigger_kind, inclusion: { in: %w[exact_match no_match] }
end

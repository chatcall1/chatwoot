class BotFlows::TriggerMatcher
  def initialize(message)
    @message = message
  end

  def call
    exact_match || eligible_no_match
  end

  private

  attr_reader :message

  def exact_match
    trigger = BotFlowTrigger.includes(:bot_flow).find_by(
      account_id: message.account_id,
      inbox_id: message.inbox_id,
      trigger_kind: 'exact_match',
      value_hash: BotFlowTrigger.fingerprint(message.content)
    )
    trigger&.bot_flow if trigger&.normalized_value == normalized_content
  end

  def eligible_no_match
    trigger = BotFlowTrigger.includes(:bot_flow).find_by(
      account_id: message.account_id,
      inbox_id: message.inbox_id,
      trigger_kind: 'no_match'
    )
    flow = trigger&.bot_flow
    flow if flow && BotFlows::NoMatchEligibility.new(flow, message.conversation.contact_id).call
  end

  def normalized_content
    @normalized_content ||= BotFlowTrigger.normalize(message.content)
  end
end

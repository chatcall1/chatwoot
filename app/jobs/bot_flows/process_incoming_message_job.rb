class BotFlows::ProcessIncomingMessageJob < ApplicationJob
  queue_as :high

  retry_on StandardError, wait: :polynomially_longer, attempts: 5

  def perform(message_id)
    message = Message.find(message_id)
    return unless processable?(message)
    return if resume_location_execution(message)
    return if resume_waiting_execution(message)

    flow = BotFlows::TriggerMatcher.new(message).call
    return unless flow

    execution = safely_create_execution(flow, message)
    return unless execution

    BotFlows::Executor.new(execution).call
  rescue ActiveRecord::RecordNotUnique
    nil
  end

  private

  def resume_waiting_execution(message)
    reply_id = message.content_attributes.dig('bot_flow_reply', 'id').to_s
    return false if reply_id.blank?

    execution = BotFlowExecution.awaiting_input.where(conversation_id: message.conversation_id).order(id: :desc).find do |candidate|
      candidate.context.fetch('expected_replies', {}).key?(reply_id)
    end
    return false unless execution

    execution.update!(context: execution.context.merge('reply_message_id' => message.id))
    BotFlows::Executor.new(execution).resume(reply_id)
    true
  end

  def processable?(message)
    message.incoming? && !message.private? && message_payload?(message) && message.account.feature_enabled?(:flow_builder)
  end

  def message_payload?(message)
    message.content.present? || message.attachments.any?(&:location?)
  end

  def resume_location_execution(message)
    location = message.attachments.find(&:location?)
    return false unless location

    execution = BotFlowExecution.awaiting_input.where(conversation_id: message.conversation_id)
                                .where("context ->> 'awaiting_location' = 'true'").order(id: :desc).first
    return false unless execution

    context = execution.context.merge(
      'received_location' => { 'latitude' => location.coordinates_lat, 'longitude' => location.coordinates_long },
      'reply_message_id' => message.id, 'awaiting_location' => false
    )
    execution.update!(context: context)
    BotFlows::Executor.new(execution).resume_location
    true
  end

  def create_execution(flow, message)
    BotFlowExecution.create_or_find_by!(trigger_message_id: message.id) do |execution|
      execution.bot_flow = flow
      execution.account = message.account
      execution.inbox = message.inbox
      execution.conversation = message.conversation
      execution.contact = message.conversation.contact
      execution.trigger_kind = flow.trigger_kind
      execution.context = { 'incoming_message_id' => message.id, 'incoming_message' => message.content }
    end
  end

  def safely_create_execution(flow, message)
    return create_execution(flow, message) unless flow.trigger_kind == 'no_match'

    flow.with_lock do
      eligibility = BotFlows::NoMatchEligibility.new(flow, message.conversation.contact_id)
      create_execution(flow, message) if eligibility.call
    end
  end
end

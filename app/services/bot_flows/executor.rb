class BotFlows::Executor
  MESSAGE_NODE_TYPES = %w[text image video document audio interactive].freeze
  META_NODE_TYPES = BotFlows::MetaNodeValidator::TYPES.freeze

  def initialize(execution)
    @execution = execution
    @definition = execution.bot_flow.published_definition.deep_stringify_keys
  end

  def call
    run_from(first_node)
  end

  def resume(reply_id)
    target_id = execution.context.fetch('expected_replies', {})[reply_id]
    raise ArgumentError, 'Interactive reply is not valid for this execution' if target_id.blank?
    return if execution.context.fetch('handled_replies', []).include?(reply_id)

    handled_replies = execution.context.fetch('handled_replies', []) | [reply_id]
    reply_label = execution.context.fetch('expected_reply_labels', {})[reply_id]
    execution.update!(
      context: execution.context.merge(
        'handled_replies' => handled_replies,
        'last_choice' => reply_label,
        'last_choice_id' => reply_id
      )
    )
    run_from(node_by_id(target_id))
  end

  def resume_location
    target_id = execution.context['location_request_target']
    raise ArgumentError, 'Location request has no following node' if target_id.blank?

    run_from(node_by_id(target_id))
  end

  private

  attr_reader :execution, :definition

  def run_from(start_node)
    execution.with_lock do
      return unless execution.pending? || execution.running? || execution.awaiting_input?

      execution.running!
      return if deliver_path(start_node) == :awaiting_input

      finish_path!
    end
  rescue StandardError => e
    execution.update!(status: :failed, context: execution.context.merge('error' => e.message))
    raise
  end

  def deliver_path(node)
    while node
      execution.update!(current_node_id: node['id'])
      if node['type'] == 'condition'
        node = condition_next_node(node)
        next
      end

      deliver(node)
      if waits_for_choice?(node)
        wait_for_reply!(node)
        return :awaiting_input
      end
      if node['type'] == 'location_request'
        wait_for_location!(node)
        return :awaiting_input
      end

      node = next_node(node)
    end
  end

  def first_node = next_node(nodes.find { |node| node['type'] == 'trigger' })

  def next_node(node) = node_by_id(outgoing_edges(node['id']).first&.fetch('target', nil))

  def condition_next_node(node)
    evaluator = BotFlows::ConditionEvaluator.new(node, execution.context)
    matched = evaluator.call
    results = execution.context.fetch('condition_results', {}).merge(
      node['id'] => { 'matched' => matched, 'source' => evaluator.source }
    )
    execution.update!(context: execution.context.merge('condition_results' => results))
    handle = matched ? 'matched' : 'not_matched'
    node_by_id(outgoing_edges(node['id'], handle).first&.fetch('target', nil))
  end

  def deliver(node)
    unless MESSAGE_NODE_TYPES.include?(node['type']) || META_NODE_TYPES.include?(node['type'])
      raise ArgumentError, "Unsupported executable node type: #{node['type']}"
    end

    delivery = execution.bot_flow_deliveries.find_or_create_by!(node_id: node['id'])
    return if delivery.message_id?

    message = Messages::MessageBuilder.new(nil, execution.conversation, message_params(node, delivery)).perform
    delivery.update!(message: message, status: :enqueued, attempt_count: 1, last_attempt_at: Time.current)
  end

  def message_params(node, delivery)
    params = {
      content: message_content(node),
      private: false,
      content_attributes: {
        bot_flow_execution_id: execution.id,
        bot_flow_delivery_id: delivery.id
      }
    }
    if META_NODE_TYPES.include?(node['type'])
      params[:content_attributes]['bot_flow_whatsapp_node'] = node.merge('triggerSourceId' => execution.trigger_message.source_id)
      return params
    end
    return media_params(params, node) if BotFlows::MediaValidator::RULES.key?(node['type'])
    return params unless node['type'] == 'interactive'

    resolver = BotFlows::InteractionResolver.new(definition, node)
    params[:content_type] = :input_select
    params[:content_attributes].merge!(resolver.content_attributes)
    params
  end

  def message_content(node)
    case node['type']
    when 'text' then node.dig('data', 'content')
    when 'interactive' then node.dig('data', 'body')
    when *BotFlows::MediaValidator::RULES.keys then node.dig('data', 'caption')
    else meta_message_content(node)
    end
  end

  def meta_message_content(node)
    node.dig('data', 'body') || contact_name(node) || location_name(node) || node.dig('data', 'emoji') || node['type']
  end

  def contact_name(node)
    node.dig('data', 'name', 'formatted_name') if node['type'] == 'contact'
  end

  def location_name(node)
    node.dig('data', 'name').presence || node.dig('data', 'address') if node['type'] == 'location'
  end

  def media_params(params, node)
    params[:attachments] = [node.dig('data', 'blobSignedId')]
    params[:is_voice_message] = node.dig('data', 'isVoiceMessage') if node['type'] == 'audio'
    params
  end

  def wait_for_reply!(node)
    choices = BotFlows::InteractionResolver.new(definition, node).choices
    expected = choices.to_h { |item| [item[:value], item[:target]] }
    execution.update!(
      status: :awaiting_input,
      context: execution.context.merge(
        'expected_replies' => expected,
        'expected_reply_labels' => choices.to_h { |item| [item[:value], item[:title]] },
        'handled_replies' => []
      )
    )
  end

  def waits_for_choice?(node)
    node['type'] == 'interactive' || (node['type'] == 'carousel' && node.dig('data', 'buttonType') == 'quick_reply')
  end

  def wait_for_location!(node)
    execution.update!(
      status: :awaiting_input,
      context: execution.context.merge(
        'awaiting_location' => true,
        'location_request_target' => outgoing_edges(node['id']).first&.fetch('target', nil)
      )
    )
  end

  def nodes = definition.fetch('nodes')

  def node_by_id(id) = nodes.find { |node| node['id'] == id }

  def outgoing_edges(node_id, handle = nil)
    definition.fetch('edges').select do |edge|
      edge['source'] == node_id && (handle.nil? || edge['sourceHandle'] == handle)
    end
  end

  def finish_path!
    expected = execution.context.fetch('expected_replies', {}).keys
    handled = execution.context.fetch('handled_replies', [])
    if expected.any? && (expected - handled).any?
      execution.update!(status: :awaiting_input)
    else
      execution.update!(status: :completed, completed_at: Time.current)
    end
  end
end

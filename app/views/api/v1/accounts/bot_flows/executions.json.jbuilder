json.array! @executions do |execution|
  definition = execution.bot_flow.published_definition.presence || execution.bot_flow.draft_definition
  nodes_by_id = definition.fetch('nodes', []).index_by { |node| node['id'] }
  json.id execution.id
  json.triggerKind execution.trigger_kind
  json.status execution.status
  json.currentNodeId execution.current_node_id
  json.createdAt execution.created_at
  json.completedAt execution.completed_at
  json.conditionResults execution.context.fetch('condition_results', {})
  json.deliveries execution.bot_flow_deliveries do |delivery|
    node = nodes_by_id[delivery.node_id].to_h
    json.id delivery.id
    json.nodeId delivery.node_id
    json.nodeType node['type']
    json.nodeLabel node.dig('data', 'label').presence || node.dig('data', 'content').presence || node.dig('data', 'body').presence
    json.status delivery.status
    json.messageId delivery.message_id
    json.providerMessageId delivery.message&.source_id
    json.attemptCount delivery.attempt_count
    json.lastAttemptAt delivery.last_attempt_at
    json.lastError delivery.last_error
    json.retryScheduledAt delivery.retry_scheduled_at
    json.canRetry delivery.manually_retryable?
  end
end

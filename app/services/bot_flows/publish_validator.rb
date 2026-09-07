class BotFlows::PublishValidator
  EXECUTABLE_NODE_TYPES = BotFlows::DefinitionValidator::SUPPORTED_NODE_TYPES

  def initialize(flow)
    @flow = flow
    @definition = flow.draft_definition.deep_stringify_keys
    @errors = BotFlows::DefinitionValidator.new(definition).errors
  end

  def errors
    validate_executable_nodes
    validate_trigger_path
    validate_exact_match
    @errors.uniq
  end

  private

  attr_reader :flow, :definition

  def nodes
    definition.fetch('nodes', [])
  end

  def edges
    definition.fetch('edges', [])
  end

  def trigger
    nodes.find { |node| node['type'] == 'trigger' }
  end

  def validate_executable_nodes
    unsupported = nodes.pluck('type').uniq - EXECUTABLE_NODE_TYPES
    @errors << "node types are not executable yet: #{unsupported.join(', ')}" if unsupported.any?
    @errors << 'text nodes must contain a message' if nodes.any? { |node| node['type'] == 'text' && node.dig('data', 'content').blank? }
    media_nodes.each { |node| @errors.concat(BotFlows::MediaValidator.new(node).errors) }
  end

  def media_nodes
    nodes.select { |node| BotFlows::MediaValidator::RULES.key?(node['type']) }
  end

  def validate_trigger_path
    outgoing = edges.count { |edge| edge['source'] == trigger&.fetch('id', nil) }
    @errors << 'trigger must have exactly one outgoing path' unless outgoing == 1
  end

  def validate_exact_match
    return unless trigger&.dig('data', 'mode') == 'exact_match'

    keywords = normalized_keywords(trigger)
    @errors << 'Exact Match requires at least one keyword' if keywords.empty?
    @errors << 'Exact Match keywords must be unique in the inbox' if conflicting_keywords?(keywords)
  end

  def normalized_keywords(node)
    Array(node.dig('data', 'keywords')).filter_map do |keyword|
      keyword.to_s.unicode_normalize(:nfkc).strip.downcase.presence
    end.uniq
  end

  def conflicting_keywords?(keywords)
    hashes = keywords.map { |keyword| BotFlowTrigger.fingerprint(keyword) }
    BotFlowTrigger.where(account_id: flow.account_id, inbox_id: flow.inbox_id, trigger_kind: 'exact_match', value_hash: hashes)
                  .where.not(bot_flow_id: flow.id).exists?
  end
end

class BotFlows::DraftValidator
  def initialize(definition)
    @definition = definition.to_h.deep_stringify_keys
    @errors = []
  end

  def errors
    validate
    @errors
  end

  private

  attr_reader :definition

  def validate
    return @errors << 'definition must contain nodes and edges arrays' unless nodes.is_a?(Array) && edges.is_a?(Array)

    validate_nodes
    validate_edges
  end

  def nodes = definition['nodes']

  def edges = definition['edges']

  def validate_nodes
    ids = nodes.filter_map { |node| node['id'].presence }
    @errors << 'node ids must be present and unique' unless ids.length == nodes.length && ids.uniq.length == ids.length
    @errors << 'definition must contain exactly one trigger node' unless nodes.one? { |node| node['type'] == 'trigger' }
    unsupported = nodes.pluck('type').uniq - BotFlows::DefinitionValidator::SUPPORTED_NODE_TYPES
    @errors << "unsupported node types: #{unsupported.join(', ')}" if unsupported.any?
  end

  def validate_edges
    node_ids = nodes.filter_map { |node| node['id'] }.to_set
    invalid = edges.any? do |edge|
      node_ids.exclude?(edge['source']) || node_ids.exclude?(edge['target']) || edge['source'] == edge['target']
    end
    @errors << 'edges must connect two different existing nodes' if invalid
  end
end

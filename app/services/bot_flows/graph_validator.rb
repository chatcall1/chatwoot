class BotFlows::GraphValidator
  def initialize(nodes, edges)
    @nodes = nodes
    @edges = edges
    @errors = []
  end

  def errors
    validate
    @errors
  end

  private

  attr_reader :nodes, :edges

  def validate
    trigger = nodes.find { |node| node['type'] == 'trigger' }
    return unless trigger

    @errors << 'trigger cannot have an incoming connection' if incoming?(trigger['id'])
    @errors << 'trigger must have exactly one outgoing connection' unless outgoing_count(trigger['id']) == 1
    @errors << 'every node must have exactly one incoming connection' if disconnected_nodes?(trigger)
    @errors << 'flow contains unreachable nodes or a cycle' unless reachable_node_ids(trigger['id']).length == nodes.length
  end

  def incoming?(node_id)
    edges.any? { |edge| edge['target'] == node_id }
  end

  def outgoing_count(node_id)
    edges.count { |edge| edge['source'] == node_id }
  end

  def disconnected_nodes?(trigger)
    nodes.reject { |node| node == trigger }.any? do |node|
      edges.count { |edge| edge['target'] == node['id'] } != 1
    end
  end

  def reachable_node_ids(trigger_id)
    visited = Set.new
    queue = [trigger_id]
    until queue.empty?
      node_id = queue.shift
      next if visited.include?(node_id)

      visited << node_id
      queue.concat(edges.select { |edge| edge['source'] == node_id }.pluck('target'))
    end
    visited
  end
end

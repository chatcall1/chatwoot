class BotFlows::InteractionResolver
  def initialize(definition, node)
    @definition = definition
    @node = node
  end

  def choices
    return carousel_choices if node['type'] == 'carousel'

    node.dig('data', 'interactionType') == 'buttons' ? button_choices : list_choices
  end

  def content_attributes
    data = node['data']
    type = data['interactionType']
    details = {
      'header_type' => data['headerType'], 'header_text' => data['headerText'],
      'header_blob_signed_id' => data['headerBlobSignedId'], 'header_filename' => data['headerFilename'],
      'footer' => data['footer']
    }
    details.merge!(list_attributes) if type == 'list'
    {
      'items' => choices.map { |choice| choice.slice(:title, :value).stringify_keys },
      'bot_flow_interactive_type' => type,
      'bot_flow_interactive' => details.compact
    }
  end

  private

  attr_reader :definition, :node

  def carousel_choices
    Array(node.dig('data', 'cards')).flat_map { |card| Array(card['replies']) }.map do |reply|
      choice(reply['title'], reply['id'], node['id'], "reply:#{reply['id']}")
    end
  end

  def button_choices
    outgoing_edges(node['id'], 'buttons').filter_map do |edge|
      button = node_by_id(edge['target'])
      next unless button

      choice(button.dig('data', 'title'), button.dig('data', 'replyId'), button['id'])
    end
  end

  def list_choices
    list_node = list_node_for
    list_rows(list_node).map do |row|
      choice(row['title'], row['id'], list_node['id'], "row:#{row['id']}").merge(description: row['description'])
    end
  end

  def choice(title, value, source_id, handle = nil)
    target = outgoing_edges(source_id, handle).first&.fetch('target', nil)
    { title: title, value: value, target: target }
  end

  def list_attributes
    list_node = list_node_for
    {
      'button_text' => list_node.dig('data', 'buttonText'),
      'sections' => list_sections(list_node).map do |section|
        { 'title' => section['title'], 'row_ids' => Array(section['rows']).pluck('id') }
      end,
      'descriptions' => choices.to_h { |item| [item[:value], item[:description]] }
    }
  end

  def list_rows(list_node) = list_sections(list_node).flat_map { |section| Array(section['rows']) }

  def list_sections(list_node)
    list_node.dig('data', 'sections') ||
      [{ 'title' => list_node.dig('data', 'sectionTitle'), 'rows' => list_node.dig('data', 'rows') }]
  end

  def list_node_for = node_by_id(outgoing_edges(node['id'], 'list').first['target'])

  def node_by_id(id) = definition.fetch('nodes').find { |candidate| candidate['id'] == id }

  def outgoing_edges(node_id, handle = nil)
    definition.fetch('edges').select do |edge|
      edge['source'] == node_id && (handle.nil? || edge['sourceHandle'] == handle)
    end
  end
end

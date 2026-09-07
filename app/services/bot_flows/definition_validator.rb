# rubocop:disable Metrics/ClassLength
class BotFlows::DefinitionValidator
  SUPPORTED_NODE_TYPES = (%w[trigger text image video document audio interactive interactive_button interactive_list condition] +
    BotFlows::MetaNodeValidator::TYPES).freeze
  SUPPORTED_TRIGGER_MODES = %w[exact_match no_match].freeze
  NO_MATCH_FREQUENCIES = %w[always daily weekly monthly].freeze
  INTERACTION_TYPES = %w[buttons list].freeze
  MEDIA_HEADER_TYPES = %w[image video document].freeze
  FOLLOWING_MESSAGE_TYPES = (%w[text image video document audio interactive condition] + BotFlows::MetaNodeValidator::TYPES).freeze
  CONDITION_SOURCES = %w[incoming_message last_choice].freeze
  CONDITION_OPERATORS = %w[equals not_equals contains not_contains].freeze
  CONDITION_HANDLES = %w[matched not_matched].freeze

  def initialize(definition, allow_empty_initial: false)
    @definition = definition.to_h.deep_stringify_keys
    @allow_empty_initial = allow_empty_initial
    @errors = []
  end

  def errors
    validate
    @errors
  end

  private

  attr_reader :definition, :allow_empty_initial

  def validate
    return @errors << 'definition must contain nodes and edges arrays' unless nodes.is_a?(Array) && edges.is_a?(Array)

    validate_nodes
    validate_edges
    validate_interactive_branches
    validate_condition_branches
    validate_carousel_branches
    validate_location_request_branches
    @errors.concat(BotFlows::GraphValidator.new(nodes, edges).errors) unless empty_initial_definition?
  end

  def nodes = definition['nodes']

  def edges = definition['edges']

  def empty_initial_definition?
    allow_empty_initial && edges.empty? && nodes.one? && nodes.first['type'] == 'trigger'
  end

  def validate_nodes
    validate_unique_node_ids
    validate_trigger
    nodes.each { |node| validate_node(node) }
  end

  def validate_unique_node_ids
    ids = nodes.filter_map { |node| node['id'].presence }
    @errors << 'node ids must be present and unique' unless ids.length == nodes.length && ids.uniq.length == ids.length
  end

  def validate_trigger
    triggers = nodes.select { |node| node['type'] == 'trigger' }
    @errors << 'definition must contain exactly one trigger node' unless triggers.one?
    return unless triggers.one?

    validate_trigger_data(triggers.first['data'].to_h)
  end

  def validate_trigger_data(data)
    mode = data['mode']
    @errors << 'trigger mode is not supported' unless SUPPORTED_TRIGGER_MODES.include?(mode)
    return unless mode == 'no_match'

    frequency = data['noMatchFrequency'] || 'always'
    @errors << 'No Match frequency is not supported' unless NO_MATCH_FREQUENCIES.include?(frequency)
  end

  def validate_node(node)
    type = node['type']
    @errors << "unsupported node type: #{type}" unless SUPPORTED_NODE_TYPES.include?(type)
    data = node['data'].to_h

    validate_message_node(type, data)
    validate_interactive_node(type, node, data)
    validate_condition(data) if type == 'condition'
    @errors.concat(BotFlows::MetaNodeValidator.new(node).errors) if BotFlows::MetaNodeValidator::TYPES.include?(type)
  end

  def validate_message_node(type, data)
    case type
    when 'text'
      @errors << 'text body cannot exceed 4096 characters' if data['content'].to_s.length > 4096
    when 'image', 'video', 'document'
      @errors << "#{type} caption cannot exceed 1024 characters" if data['caption'].to_s.length > 1024
    end
  end

  def validate_interactive_node(type, node, data)
    case type
    when 'interactive'
      validate_interactive(node)
    when 'interactive_button'
      validate_button(data)
    when 'interactive_list'
      validate_list(data)
    end
  end

  def validate_interactive(node)
    data = node['data'].to_h
    interaction_type = data['interactionType']
    @errors << 'interactive message must select buttons or list' unless INTERACTION_TYPES.include?(interaction_type)
    validate_interactive_body(data, interaction_type)
    validate_interactive_header(data, interaction_type)
  end

  def validate_interactive_body(data, interaction_type)
    @errors << 'interactive message body is required' if data['body'].blank?
    body_limit = interaction_type == 'list' ? 4096 : 1024
    @errors << "interactive message body cannot exceed #{body_limit} characters" if data['body'].to_s.length > body_limit
    @errors << 'interactive footer cannot exceed 60 characters' if data['footer'].to_s.length > 60
  end

  def validate_interactive_header(data, interaction_type)
    header_type = data['headerType'].presence || 'none'
    allowed_headers = interaction_type == 'list' ? %w[none text] : %w[none text image video document]
    @errors << 'interactive header type is not supported' unless allowed_headers.include?(header_type)
    validate_text_header(data) if header_type == 'text'
    return unless MEDIA_HEADER_TYPES.include?(header_type)

    media_node = { 'type' => header_type, 'data' => { 'blobSignedId' => data['headerBlobSignedId'] } }
    @errors.concat(BotFlows::MediaValidator.new(media_node).errors)
  end

  def validate_text_header(data)
    return if data['headerText'].to_s.length.between?(1, 60)

    @errors << 'interactive text header is required and cannot exceed 60 characters'
  end

  def validate_button(data)
    @errors << 'button title is required and cannot exceed 20 characters' unless data['title'].to_s.length.between?(1, 20)
    @errors << 'button reply id is required and cannot exceed 256 characters' unless data['replyId'].to_s.length.between?(1, 256)
  end

  def validate_condition(data)
    @errors << 'condition source is not supported' unless CONDITION_SOURCES.include?(data['source'])
    @errors << 'condition operator is not supported' unless CONDITION_OPERATORS.include?(data['operator'])
    @errors << 'condition comparison value is required' if data['value'].blank?
    @errors << 'condition comparison value cannot exceed 4096 characters' if data['value'].to_s.length > 4096
  end

  def validate_condition_branches
    nodes.select { |node| node['type'] == 'condition' }.each do |node|
      validate_condition_outputs(node)
    end
  end

  def validate_condition_outputs(node)
    outgoing = edges.select { |edge| edge['source'] == node['id'] }
    valid = CONDITION_HANDLES.all? { |handle| valid_condition_handle?(outgoing, handle) }
    valid &&= outgoing.all? { |edge| CONDITION_HANDLES.include?(edge['sourceHandle']) }
    @errors << 'condition must connect both result branches to following nodes' unless valid
  end

  def valid_condition_handle?(outgoing, handle)
    outgoing.one? { |edge| edge['sourceHandle'] == handle && following_message?(edge) }
  end

  def validate_carousel_branches
    quick_reply_carousels.each { |node| validate_carousel_outputs(node) }
  end

  def quick_reply_carousels
    nodes.select { |node| node['type'] == 'carousel' && node.dig('data', 'buttonType') == 'quick_reply' }
  end

  def validate_carousel_outputs(node)
    handles = Array(node.dig('data', 'cards')).flat_map do |card|
      Array(card['replies']).map { |reply| "reply:#{reply['id']}" }
    end
    outgoing = edges.select { |edge| edge['source'] == node['id'] }
    valid = carousel_handles_connected?(handles, outgoing) && carousel_outputs_known?(handles, outgoing)
    @errors << 'every carousel quick reply must connect to one following node' unless valid
  end

  def carousel_handles_connected?(handles, outgoing)
    handles.all? { |handle| valid_condition_handle?(outgoing, handle) }
  end

  def carousel_outputs_known?(handles, outgoing)
    outgoing.all? { |edge| handles.include?(edge['sourceHandle']) }
  end

  def validate_location_request_branches
    nodes.select { |node| node['type'] == 'location_request' }.each do |node|
      outgoing = edges.select { |edge| edge['source'] == node['id'] }
      valid = outgoing.one? && following_message?(outgoing.first)
      @errors << 'location request must connect to exactly one following node' unless valid
    end
  end

  def validate_list(data)
    sections = list_sections(data)
    @errors << 'interactive list must contain between 1 and 10 sections' unless sections.length.between?(1, 10)
    rows = sections.flat_map { |section| Array(section['rows']) }
    @errors << 'interactive list must contain between 1 and 10 rows' unless rows.is_a?(Array) && rows.length.between?(1, 10)
    return unless rows.is_a?(Array) && rows.any?

    validate_list_labels(data, sections)
    validate_list_rows(rows)
  end

  def list_sections(data)
    return data['sections'] if data['sections'].is_a?(Array)

    [{ 'title' => data['sectionTitle'], 'rows' => data['rows'] }]
  end

  def validate_list_labels(data, sections)
    @errors << 'list button text is required and cannot exceed 20 characters' unless data['buttonText'].to_s.length.between?(1, 20)
    valid_titles = sections.all? { |section| section['title'].to_s.length.between?(1, 24) }
    @errors << 'list section title is required and cannot exceed 24 characters' unless valid_titles
  end

  def validate_list_rows(rows)
    titles, descriptions, ids = rows.pluck('title', 'description', 'id').transpose
    @errors << 'list row title is required and cannot exceed 24 characters' unless lengths_valid?(titles, 1..24)
    @errors << 'list row description cannot exceed 72 characters' unless lengths_valid?(descriptions, 0..72)
    @errors << 'list row id is required and cannot exceed 200 characters' unless lengths_valid?(ids, 1..200)
    @errors << 'list row ids must be unique' unless rows.pluck('id').compact.uniq.length == rows.length
  end

  def validate_edges
    node_ids = nodes.filter_map { |node| node['id'] }.to_set
    edges.each do |edge|
      next if node_ids.include?(edge['source']) && node_ids.include?(edge['target']) && edge['source'] != edge['target']

      @errors << 'edges must connect two different existing nodes'
    end
  end

  def validate_interactive_branches
    nodes.select { |node| node['type'] == 'interactive' }.each do |node|
      outgoing = edges.select { |edge| edge['source'] == node['id'] }
      validate_branch_limit(outgoing, 'buttons', 3, 'interactive messages support up to three reply buttons')
      validate_branch_limit(outgoing, 'list', 1, 'interactive messages support one list branch')
      validate_branch_limit(outgoing, 'next', 1, 'interactive messages support one next branch')
      validate_selected_interaction(node, outgoing)
    end

    validate_interactive_children('interactive_button', 'buttons')
    validate_interactive_children('interactive_list', 'list')
  end

  def validate_selected_interaction(node, outgoing)
    selected = node.dig('data', 'interactionType')
    choice_edges = outgoing.select { |edge| INTERACTION_TYPES.include?(edge['sourceHandle']) }
    @errors << 'interactive message cannot use buttons and a list together' if choice_edges.pluck('sourceHandle').uniq.length > 1
    validate_matching_branch(selected, choice_edges)
    validate_choice_count(selected, choice_edges)
    validate_unique_buttons(choice_edges) if selected == 'buttons'
  end

  def validate_matching_branch(selected, choice_edges)
    return if selected.blank? || choice_edges.all? { |edge| edge['sourceHandle'] == selected }

    @errors << 'interactive branch must match the selected interaction type'
  end

  def validate_choice_count(selected, choice_edges)
    selected_count = choice_edges.count { |edge| edge['sourceHandle'] == selected }
    valid_count = selected == 'buttons' ? selected_count.between?(1, 3) : selected_count == 1
    @errors << 'interactive message must contain its selected branch' unless valid_count
  end

  def validate_unique_buttons(choice_edges)
    buttons = choice_edges.filter_map do |edge|
      nodes.find { |candidate| candidate['id'] == edge['target'] && candidate['type'] == 'interactive_button' }
    end
    @errors << 'interactive button titles must be unique' unless unique_button_values?(buttons, 'title', normalize: true)
    @errors << 'interactive button reply ids must be unique' unless unique_button_values?(buttons, 'replyId')
  end

  def unique_button_values?(buttons, key, normalize: false)
    values = buttons.filter_map do |button|
      value = button.dig('data', key).to_s.strip
      value = value.downcase if normalize
      value.presence
    end
    values.uniq.length == buttons.length
  end

  def lengths_valid?(values, range) = values.all? { |value| range.cover?(value.to_s.length) }

  def validate_branch_limit(edges, handle, limit, message)
    @errors << message if edges.count { |edge| edge['sourceHandle'] == handle } > limit
  end

  def validate_interactive_children(node_type, source_handle)
    nodes.select { |node| node['type'] == node_type }.each do |node|
      incoming = edges.select { |edge| edge['target'] == node['id'] }
      @errors << "#{node_type} must belong to an interactive node" unless valid_interactive_parent?(incoming, source_handle)
      validate_child_outputs(node, node_type)
    end
  end

  def validate_child_outputs(node, node_type)
    outgoing = edges.select { |edge| edge['source'] == node['id'] }
    if node_type == 'interactive_list'
      validate_list_outputs(node, outgoing)
    else
      @errors << "#{node_type} must connect to exactly one following message" unless outgoing.one? && following_message?(outgoing.first)
    end
  end

  def validate_list_outputs(node, outgoing)
    rows = list_sections(node['data'].to_h).flat_map { |section| Array(section['rows']) }
    handles = rows.map { |row| "row:#{row['id']}" }
    valid = handles.all? { |handle| valid_list_handle?(outgoing, handle) }
    valid &&= outgoing.all? { |edge| handles.include?(edge['sourceHandle']) }
    @errors << 'every interactive list row must connect to one following message' unless valid
  end

  def valid_list_handle?(outgoing, handle)
    outgoing.one? { |edge| edge['sourceHandle'] == handle && following_message?(edge) }
  end

  def following_message?(edge)
    FOLLOWING_MESSAGE_TYPES.include?(nodes.find { |node| node['id'] == edge['target'] }.to_h['type'])
  end

  def valid_interactive_parent?(incoming, source_handle)
    return false unless incoming.one? && incoming.first['sourceHandle'] == source_handle

    source = incoming.first['source']
    nodes.any? { |candidate| candidate['id'] == source && candidate['type'] == 'interactive' }
  end
end
# rubocop:enable Metrics/ClassLength

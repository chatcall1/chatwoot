class Whatsapp::TemplateButtonParameterProcessor
  pattr_initialize [:channel!, :template!, :processed_params!, :message]

  def call
    process_standard_buttons + process_authentication_button + process_flow_button
  end

  private

  def process_standard_buttons
    return [] if processed_params['buttons'].blank?

    occurrences = Hash.new(0)
    processed_params['buttons'].filter_map do |button|
      next if button.blank? || (button['type'] != 'url' && button['parameter'].blank?)

      build_button_component(button, occurrences)
    end
  end

  def build_button_component(button, occurrences)
    type = button['type'].to_s.upcase
    index = matching_index(type, occurrences[type])
    occurrences[type] += 1
    raise ArgumentError, "Template button definition is missing for #{type}" if index.nil?

    {
      type: 'button', sub_type: button['type'] || 'url', index: index.to_s,
      parameters: [parameter_builder.build_button_parameter(button)]
    }
  end

  def matching_index(type, occurrence)
    matching_indexes = button_definitions.each_index.select do |index|
      button_definitions[index]['type'].to_s.upcase == type
    end
    matching_indexes[occurrence]
  end

  def process_authentication_button
    return [] unless template['category']&.casecmp?('AUTHENTICATION')

    otp = processed_params['body']&.values&.first.to_s
    raise ArgumentError, 'Authentication code is required' if otp.blank?
    raise ArgumentError, 'Authentication code must not exceed 15 characters' if otp.length > 15

    [{ type: 'button', sub_type: 'url', index: '0', parameters: [{ type: 'text', text: otp }] }]
  end

  def process_flow_button
    flow_index = button_definitions.index { |button| button['type'] == 'FLOW' }
    return [] if flow_index.nil?

    [{
      type: 'button', sub_type: 'flow', index: flow_index.to_s,
      parameters: [{ type: 'action', action: { flow_token: flow_token } }]
    }]
  end

  def flow_token
    return "chatwoot_#{channel.account_id}_#{message.id}" if message

    "chatwoot_#{SecureRandom.uuid}"
  end

  def button_definitions
    @button_definitions ||= template['components']&.find do |component|
      component['type'] == 'BUTTONS'
    end&.fetch('buttons', []) || []
  end

  def parameter_builder
    @parameter_builder ||= Whatsapp::PopulateTemplateParametersService.new
  end
end

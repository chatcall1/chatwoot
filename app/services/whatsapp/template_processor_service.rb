class Whatsapp::TemplateProcessorService
  pattr_initialize [:channel!, :template_params, :message]

  def call
    return [nil, nil, nil, nil] if template_params.blank?

    process_template_with_params
  end

  private

  def process_template_with_params
    [
      template_params['name'],
      template_params['namespace'],
      template_params['language'],
      processed_templates_params
    ]
  end

  def find_template
    channel.message_templates.find do |t|
      t['name'] == template_params['name'] &&
        t['language']&.downcase == template_params['language']&.downcase &&
        t['status']&.downcase == 'approved'
    end
  end

  def processed_templates_params
    template = find_template
    return if template.blank?

    # Convert legacy format to enhanced format before processing
    converter = Whatsapp::TemplateParameterConverterService.new(template_params, template)
    normalized_params = converter.normalize_to_enhanced

    process_enhanced_template_params(template, normalized_params['processed_params'])
  end

  def process_enhanced_template_params(template, processed_params = nil)
    processed_params ||= template_params['processed_params']
    components = []

    components.concat(process_header_components(processed_params, template))
    components.concat(process_body_components(processed_params, template))
    components.concat(process_footer_components(processed_params))
    components.concat(process_button_components(processed_params))
    components.concat(process_flow_button(template))
    components.concat(process_carousel_components(processed_params, template))

    @template_params = components
  end

  def process_flow_button(template)
    buttons = template['components']&.find { |component| component['type'] == 'BUTTONS' }&.fetch('buttons', []) || []
    flow_index = buttons.index { |button| button['type'] == 'FLOW' }
    return [] if flow_index.nil?

    token = message ? "chatwoot_#{channel.account_id}_#{message.id}" : "chatwoot_#{SecureRandom.uuid}"
    [{
      type: 'button',
      sub_type: 'flow',
      index: flow_index.to_s,
      parameters: [{ type: 'action', action: { flow_token: token } }]
    }]
  end

  def process_header_components(processed_params, template)
    return [] if processed_params['header'].blank?

    header_params = build_header_params(processed_params['header'], template)
    header_params.present? ? [{ type: 'header', parameters: header_params }] : []
  end

  def build_header_params(header_data, template)
    header_component = template['components']&.find { |component| component['type'] == 'HEADER' }
    return build_text_header_params(header_data, template) if header_component&.dig('format') == 'TEXT'

    build_media_header_params(header_data)
  end

  def build_text_header_params(header_data, template)
    header_data.filter_map do |key, value|
      build_text_parameter(key, value, template) if value.present?
    end
  end

  def build_media_header_params(header_data)
    return [] if header_data['media_url'].blank? || header_data['media_type'].blank?

    media_param = parameter_builder.build_media_parameter(header_data['media_url'], header_data['media_type'], header_data['media_name'])
    media_param ? [media_param] : []
  end

  def process_body_components(processed_params, template)
    return [] if processed_params['body'].blank?

    body_parameters = processed_params['body']
    body_parameters = body_parameters.sort_by { |key, _value| key.to_i } unless template['parameter_format'] == 'NAMED'

    body_params = body_parameters.filter_map do |key, value|
      next if value.blank?

      build_text_parameter(key, value, template)
    end

    body_params.present? ? [{ type: 'body', parameters: body_params }] : []
  end

  def build_text_parameter(key, value, template)
    return parameter_builder.build_named_parameter(key, value) if template['parameter_format'] == 'NAMED'

    parameter_builder.build_parameter(value)
  end

  def process_footer_components(processed_params)
    return [] if processed_params['footer'].blank?

    footer_params = processed_params['footer'].filter_map do |_, value|
      next if value.blank?

      parameter_builder.build_parameter(value)
    end

    footer_params.present? ? [{ type: 'footer', parameters: footer_params }] : []
  end

  def process_button_components(processed_params)
    return [] if processed_params['buttons'].blank?

    button_params = processed_params['buttons'].filter_map.with_index do |button, index|
      next if button.blank?

      if button['type'] == 'url' || button['parameter'].present?
        {
          type: 'button',
          sub_type: button['type'] || 'url',
          index: index,
          parameters: [parameter_builder.build_button_parameter(button)]
        }
      end
    end

    button_params.compact
  end

  def process_carousel_components(processed_params, template)
    carousel = template['components']&.find { |component| component['type'] == 'CAROUSEL' }
    return [] if carousel.blank?

    cards = carousel['cards'].filter_map.with_index do |card, card_index|
      build_carousel_card(processed_params, template, card, card_index)
    end

    cards.present? ? [{ type: 'carousel', cards: cards }] : []
  end

  def build_carousel_card(processed_params, template, card, card_index)
    header = carousel_card_media_header(card)
    return if header.blank?

    media_url = carousel_media_url(template['name'], card_index, header)
    media_parameter = parameter_builder.build_media_parameter(media_url, header['format'])
    components = [{ type: 'header', parameters: [media_parameter] }]
    components.concat(process_carousel_card_body(processed_params, template, card_index))
    components.concat(process_carousel_card_buttons(processed_params, card, card_index))
    { card_index: card_index, components: components }
  end

  def carousel_card_media_header(card)
    card['components']&.find do |component|
      component['type'] == 'HEADER' && %w[IMAGE VIDEO].include?(component['format'])
    end
  end

  def carousel_media_url(template_name, card_index, header)
    stored_media = channel.template_media.find_by(template_name: template_name, card_index: card_index)
    return stored_media.download_url if stored_media&.file&.attached?

    header.dig('example', 'header_handle', 0).presence || raise(ArgumentError, "Carousel card #{card_index + 1} media is missing")
  end

  def process_carousel_card_body(processed_params, template, card_index)
    values = carousel_card_params(processed_params, card_index, 'body')
    return [] if values.blank?

    values = values.sort_by { |key, _value| key.to_i } unless template['parameter_format'] == 'NAMED'
    parameters = values.filter_map { |key, value| build_text_parameter(key, value, template) if value.present? }
    parameters.present? ? [{ type: 'body', parameters: parameters }] : []
  end

  def process_carousel_card_buttons(processed_params, card, card_index)
    definitions = carousel_button_definitions(card)
    values = carousel_card_params(processed_params, card_index, 'buttons') || []

    definitions.filter_map.with_index do |definition, button_index|
      button = values[button_index] || {}
      carousel_button_component(definition, button, button_index)
    end
  end

  def carousel_button_definitions(card)
    component = card.fetch('components', []).find { |item| item['type'] == 'BUTTONS' }
    component&.fetch('buttons', []) || []
  end

  def carousel_button_component(definition, button, button_index)
    if definition['type'] == 'QUICK_REPLY'
      payload = button['parameter'].presence || definition['text']
      return { type: 'button', sub_type: 'quick_reply', index: button_index, parameters: [{ type: 'payload', payload: payload }] }
    end

    return unless definition['type'] == 'URL' && definition['url'].to_s.include?('{{')
    raise ArgumentError, "Carousel button #{button_index + 1} parameter is missing" if button['parameter'].blank?

    { type: 'button', sub_type: 'url', index: button_index, parameters: [parameter_builder.build_button_parameter(button.merge('type' => 'url'))] }
  end

  def carousel_card_params(processed_params, card_index, component)
    cards = processed_params.dig('carousel', 'cards') || {}
    (cards[card_index.to_s] || cards[card_index] || {})[component]
  end

  def parameter_builder
    @parameter_builder ||= Whatsapp::PopulateTemplateParametersService.new
  end
end

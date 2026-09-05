class Whatsapp::TemplateRequestBuilder
  POSITIONAL_VARIABLE_PATTERN = /\{\{(\d+)\}\}/
  NAMED_VARIABLE_PATTERN = /\{\{([a-z][a-z_]*)\}\}/
  SYSTEM_BUTTON_TEXT = {
    'ar' => { 'CATALOG' => 'عرض الكتالوج', 'MPM' => 'عرض العناصر', 'SPM' => 'عرض' },
    'en_US' => { 'CATALOG' => 'View catalog', 'MPM' => 'View items', 'SPM' => 'View' }
  }.freeze

  def initialize(payload)
    @payload = payload
  end

  def build(handles)
    return Whatsapp::AuthenticationTemplateBuilder.new(@payload).build if @payload['category'] == 'AUTHENTICATION'
    return catalog_request_body if @payload['catalog_format'].present?
    return standard_request_body(handles.first) if @payload['template_format'] == 'standard'

    template_request([body_component(@payload['body'], @payload['body_examples']), carousel_component(handles)], 'MARKETING')
  end

  private

  def standard_request_body(header_handle)
    components = []
    components << standard_header_component(header_handle) unless @payload['header_type'] == 'none'
    components << body_component(@payload['body'], @payload['body_examples'])
    components << { type: 'FOOTER', text: @payload['footer'] } if @payload['footer'].to_s.present?
    components << buttons_component_for(@payload['buttons']) if @payload['buttons'].present?
    template_request(components, @payload['category'])
  end

  def standard_header_component(header_handle)
    return media_header_component(header_handle) unless @payload['header_type'] == 'text'

    { type: 'HEADER', format: 'TEXT', text: @payload['header_text'] }.tap do |component|
      component[:example] = header_example if @payload['header_text'].match?(variable_pattern)
    end
  end

  def media_header_component(header_handle)
    { type: 'HEADER', format: @payload['header_type'].upcase, example: { header_handle: [header_handle] } }
  end

  def buttons_component_for(buttons)
    { type: 'BUTTONS', buttons: buttons.map { |button| standard_button_payload(button) } }
  end

  def standard_button_payload(button)
    return { type: 'COPY_CODE', example: button['example'].strip } if button['type'] == 'COPY_CODE'

    { type: button['type'], text: button['text'].strip }.tap do |result|
      add_button_destination(result, button)
      add_app_deep_link(result, button)
      result[:example] = [button['example'].strip] if dynamic_url?(button)
    end
  end

  def add_button_destination(result, button)
    result[:url] = button['value'].strip if button['type'] == 'URL'
    result[:phone_number] = button['value'].strip if button['type'] == 'PHONE_NUMBER'
    result[:flow_id] = button['flow_id'] if button['type'] == 'FLOW'
  end

  def add_app_deep_link(result, button)
    return if button['app_deep_link'].blank?

    result[:app_deep_link] = button['app_deep_link'].deep_symbolize_keys
    result[:app_deep_link][:meta_app_id] = result[:app_deep_link][:meta_app_id].to_i
  end

  def dynamic_url?(button)
    button['type'] == 'URL' && button['value'].match?(variable_pattern)
  end

  def catalog_request_body
    components = case @payload['catalog_format']
                 when 'product_carousel' then [body_component(@payload['body'], @payload['body_examples']), product_carousel_component]
                 when 'products' then product_template_components
                 else catalog_template_components
                 end
    template_request(components, 'MARKETING')
  end

  def catalog_template_components
    components = [body_component(@payload['body'], @payload['body_examples'])]
    components << { type: 'FOOTER', text: @payload['footer'] } if @payload['footer'].to_s.present?
    components << { type: 'BUTTONS', buttons: [{ type: 'CATALOG', text: system_button_text('CATALOG') }] }
  end

  def product_template_components
    button_type = @payload['product_template_type'] == 'mpm' ? 'MPM' : 'SPM'
    components = product_header_components(button_type)
    components << body_component(@payload['body'], @payload['body_examples'])
    components << { type: 'FOOTER', text: @payload['footer'] } if @payload['footer'].to_s.present?
    components << { type: 'BUTTONS', buttons: [{ type: button_type, text: system_button_text(button_type) }] }
  end

  def product_header_components(button_type)
    return [{ type: 'HEADER', format: 'PRODUCT' }] if button_type == 'SPM'

    [{ type: 'HEADER', format: 'TEXT', text: @payload['header_text'] }.tap do |component|
      component[:example] = header_example if @payload['header_text'].match?(variable_pattern)
    end]
  end

  def product_carousel_component
    button = product_carousel_button
    card = { components: [{ type: 'HEADER', format: 'PRODUCT' }, { type: 'BUTTONS', buttons: [button] }] }
    { type: 'CAROUSEL', cards: [card.deep_dup, card.deep_dup] }
  end

  def product_carousel_button
    return { type: 'SPM', text: system_button_text('SPM') } unless @payload['product_carousel_button_type'] == 'URL'

    data = @payload.fetch('product_carousel_button')
    { type: 'URL', text: data['text'].strip, url: data['url'].strip }.tap do |button|
      button[:example] = [data['example'].strip] if data['url'].match?(variable_pattern)
    end
  end

  def carousel_component(handles)
    cards = @payload['cards'].each_with_index.map { |card, index| { components: card_components(card, handles[index]) } }
    { type: 'CAROUSEL', cards: cards }
  end

  def card_components(card, media_handle)
    components = [{ type: 'HEADER', format: @payload['media_type'], example: { header_handle: [media_handle] } }]
    components << body_component(card['body'], card['body_examples']) if @payload['card_text_enabled']
    components << carousel_buttons_component(card) if @payload['button_types'].any?
    components
  end

  def body_component(text, examples)
    { type: 'BODY', text: text }.tap do |component|
      component[:example] = body_examples(examples) if examples.any?
    end
  end

  def body_examples(examples)
    return { body_text: [examples] } unless named_parameters?

    { body_text_named_params: examples.map { |name, example| { param_name: name, example: example } } }
  end

  def carousel_buttons_component(card)
    buttons = @payload['button_types'].map { |type| carousel_button_payload(card['buttons'].fetch(type), type) }
    { type: 'BUTTONS', buttons: buttons }
  end

  def carousel_button_payload(button, type)
    { type: type, text: button['text'].strip }.tap do |result|
      result[:url] = button['value'].strip if type == 'URL'
      result[:phone_number] = button['value'].strip if type == 'PHONE_NUMBER'
      result[:example] = [button['example'].strip] if type == 'URL' && button['value'].match?(variable_pattern)
    end
  end

  def template_request(components, category)
    { name: @payload['name'], language: @payload['language'], category: category,
      parameter_format: parameter_format.downcase, components: components }
  end

  def header_example
    return { header_text: [@payload['header_example']] } unless named_parameters?

    name = @payload['header_text'].scan(NAMED_VARIABLE_PATTERN).flatten.first
    { header_text_named_params: [{ param_name: name, example: @payload['header_example'] }] }
  end

  def system_button_text(type)
    SYSTEM_BUTTON_TEXT.fetch(@payload['language']).fetch(type)
  end

  def named_parameters?
    parameter_format == 'NAMED'
  end

  def parameter_format
    (@payload['parameter_format'].presence || 'POSITIONAL').to_s.upcase
  end

  def variable_pattern
    named_parameters? ? NAMED_VARIABLE_PATTERN : POSITIONAL_VARIABLE_PATTERN
  end
end

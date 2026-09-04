class Whatsapp::TemplateCreationService
  class ValidationError < StandardError; end

  class ApiError < StandardError
    attr_reader :details

    def initialize(message, details: nil)
      super(message)
      @details = details
    end
  end

  VARIABLE_PATTERN = /\{\{(\d+)\}\}/
  SYSTEM_BUTTON_TEXT = {
    'ar' => { 'CATALOG' => 'عرض الكتالوج', 'MPM' => 'عرض العناصر', 'SPM' => 'عرض' },
    'en' => { 'CATALOG' => 'View catalog', 'MPM' => 'View items', 'SPM' => 'View' }
  }.freeze

  def initialize(channel)
    @channel = channel
  end

  def create!(payload:, media_files:)
    @payload = payload
    @media_files = media_files
    Whatsapp::TemplateValidator.new(payload: @payload, media_files: @media_files).validate!

    api_client = Whatsapp::TemplateApiClient.new(@channel)
    handles = @media_files.compact.map { |file| api_client.upload_media!(file) }
    response = api_client.create_template!(request_body(handles))
    persist_template_media!

    {
      id: response['id'],
      name: @payload['name'],
      status: response['status'] || 'PENDING',
      category: response['category'] || 'MARKETING',
      language: @payload['language']
    }
  end

  private

  def persist_template_media!
    return if @payload['catalog_format'].present?

    WhatsappTemplateMedia.transaction do
      @channel.template_media.where(template_name: @payload['name']).destroy_all
      @media_files.each_with_index do |file, card_index|
        media = @channel.template_media.create!(
          template_name: @payload['name'],
          card_index: card_index,
          media_type: @payload['media_type'].downcase
        )
        media.file.attach(file)
      end
    end
  end

  def request_body(handles)
    return catalog_request_body if @payload['catalog_format'].present?
    return standard_request_body if @payload['template_format'] == 'standard'

    {
      name: @payload['name'],
      language: @payload['language'],
      category: 'MARKETING',
      components: [body_component(@payload['body'], @payload['body_examples']), carousel_component(handles)]
    }
  end

  def standard_request_body
    components = []
    components << { type: 'HEADER', format: 'TEXT', text: @payload['header_text'] } if @payload['header_type'] == 'text'
    components << body_component(@payload['body'], @payload['body_examples'])
    components << { type: 'FOOTER', text: @payload['footer'] } if @payload['footer'].to_s.present?
    components << {
      type: 'BUTTONS',
      buttons: [{ type: 'FLOW', text: @payload.dig('button', 'text'), flow_id: @payload.dig('button', 'flow_id') }]
    }

    { name: @payload['name'], language: @payload['language'], category: 'MARKETING', components: components }
  end

  def catalog_request_body
    components = case @payload['catalog_format']
                 when 'product_carousel'
                   [body_component(@payload['body'], @payload['body_examples']), product_carousel_component]
                 when 'products'
                   product_template_components
                 else
                   catalog_template_components
                 end
    { name: @payload['name'], language: @payload['language'], category: 'MARKETING', components: components }
  end

  def catalog_template_components
    components = [body_component(@payload['body'], @payload['body_examples'])]
    components << { type: 'FOOTER', text: @payload['footer'] } if @payload['footer'].to_s.present?
    components << { type: 'BUTTONS', buttons: [{ type: 'CATALOG', text: system_button_text('CATALOG') }] }
    components
  end

  def product_template_components
    button_type = @payload['product_template_type'] == 'mpm' ? 'MPM' : 'SPM'
    components = []
    components << { type: 'HEADER', format: 'PRODUCT' } if button_type == 'SPM'
    components << body_component(@payload['body'], @payload['body_examples'])
    components << { type: 'FOOTER', text: @payload['footer'] } if @payload['footer'].to_s.present?
    components << { type: 'BUTTONS', buttons: [{ type: button_type, text: system_button_text(button_type) }] }
    components
  end

  def product_carousel_component
    button_type = @payload['product_carousel_button_type']
    button = if button_type == 'URL'
               data = @payload.fetch('product_carousel_button')
               { type: 'URL', text: data['text'].strip, url: data['url'].strip }.tap do |value|
                 value[:example] = [data['example'].strip] if data['url'].match?(VARIABLE_PATTERN)
               end
             else
               { type: 'SPM', text: system_button_text('SPM') }
             end
    card = { components: [{ type: 'HEADER', format: 'PRODUCT' }, { type: 'BUTTONS', buttons: [button] }] }
    { type: 'CAROUSEL', cards: [card.deep_dup, card.deep_dup] }
  end

  def carousel_component(handles)
    {
      type: 'CAROUSEL',
      cards: @payload['cards'].each_with_index.map do |card, index|
        { components: card_components(card, handles[index]) }
      end
    }
  end

  def card_components(card, media_handle)
    components = [
      {
        type: 'HEADER',
        format: @payload['media_type'],
        example: { header_handle: [media_handle] }
      }
    ]
    components << body_component(card['body'], card['body_examples']) if @payload['card_text_enabled']
    components << buttons_component(card) if @payload['button_types'].any?
    components
  end

  def body_component(text, examples)
    component = { type: 'BODY', text: text }
    component[:example] = { body_text: [examples] } if examples.any?
    component
  end

  def buttons_component(card)
    {
      type: 'BUTTONS',
      buttons: @payload['button_types'].map { |type| button_payload(card['buttons'].fetch(type), type) }
    }
  end

  def button_payload(button, type)
    payload = { type: type, text: button['text'].strip }
    payload[:url] = button['value'].strip if type == 'URL'
    payload[:phone_number] = button['value'].strip if type == 'PHONE_NUMBER'
    payload[:example] = [button['example'].strip] if type == 'URL' && button['value'].match?(VARIABLE_PATTERN)
    payload
  end

  def system_button_text(type)
    SYSTEM_BUTTON_TEXT.fetch(@payload['language']).fetch(type)
  end
end

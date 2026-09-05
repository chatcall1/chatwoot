class Whatsapp::TemplateValidator
  delegate :variable_names, to: :variable_validator

  ALLOWED_LANGUAGES = %w[ar en_US].freeze
  ALLOWED_MEDIA_TYPES = {
    'IMAGE' => { content_types: %w[image/jpeg image/png], max_size: 5.megabytes },
    'VIDEO' => { content_types: %w[video/mp4 video/3gpp], max_size: 16.megabytes }
  }.freeze
  ALLOWED_HEADER_MEDIA_TYPES = ALLOWED_MEDIA_TYPES.merge(
    'DOCUMENT' => { content_types: ['application/pdf'], max_size: 100.megabytes },
    'GIF' => { content_types: ['video/mp4'], max_size: 3.5.megabytes }
  ).freeze
  ALLOWED_BUTTON_TYPES = %w[QUICK_REPLY URL PHONE_NUMBER].freeze
  MAX_BODY_LENGTH = 1024
  MAX_CARD_BODY_LENGTH = 160
  MAX_BUTTON_TEXT_LENGTH = 25
  MAX_CARD_LINE_BREAKS = 2
  MAX_CARDS = 10
  MIN_CARDS = 2
  PHONE_NUMBER_PATTERN = /\A[+\d][\d\s().-]{5,19}\z/
  TEMPLATE_NAME_PATTERN = /\A[a-z0-9_]+\z/

  def initialize(payload:, media_files:)
    @payload = payload
    @media_files = media_files
  end

  def validate!
    validate_identity!
    return Whatsapp::AuthenticationTemplateBuilder.new(@payload).validate! if @payload['category'] == 'AUTHENTICATION'
    return validate_catalog! if @payload['catalog_format'].present?
    return validate_standard! if @payload['template_format'] == 'standard'

    validate_body!(@payload['body'], max_length: MAX_BODY_LENGTH, required: true, label: 'Message body')
    validate_examples!(@payload['body'], @payload['body_examples'], 'Message body')
    validate_cards!
    validate_button_types!
    @payload['cards'].each_with_index { |card, index| validate_card!(card, index) }
  end

  def validate_standard!
    validate_body!(@payload['body'], max_length: MAX_BODY_LENGTH, required: true, label: 'Message body')
    validate_examples!(@payload['body'], @payload['body_examples'], 'Message body')
    validate_standard_copy!
    validate_standard_buttons!
  end

  def validate_standard_copy!
    validate_body!(@payload['footer'], max_length: 60, required: false, label: 'Footer')
    fail!('Footer cannot contain variables') if variable_names(@payload['footer'].to_s).any?
    fail!('Invalid header type') unless %w[none text image video document gif].include?(@payload['header_type'])
    fail!('GIF headers require the Marketing category') if @payload['header_type'] == 'gif' && @payload['category'] != 'MARKETING'
    validate_text_header! if @payload['header_type'] == 'text'
    validate_standard_header_media! if %w[image video document gif].include?(@payload['header_type'])
  end

  def validate_standard_buttons!
    Whatsapp::TemplateButtonValidator.new(payload: @payload, variable_validator: variable_validator).validate!
  end

  def validate_text_header!
    validate_body!(@payload['header_text'], max_length: 60, required: true, label: 'Header')
    indexes = variable_names(@payload['header_text'].to_s)
    fail!('Text header supports one variable') if indexes.length > 1
    fail!('Text header variable example is required') if indexes.one? && @payload['header_example'].to_s.blank?
  end

  def validate_standard_header_media!
    fail!('Header media file is required') unless @media_files.one?
    rules = ALLOWED_HEADER_MEDIA_TYPES.fetch(@payload['header_type'].upcase)
    file = @media_files.first
    fail!('Header media file type is invalid') unless rules[:content_types].include?(file.content_type)
    fail!('Header media file is too large') if file.size > rules[:max_size]
  end

  def validate_catalog!
    fail!('A catalog must be selected') if @payload['catalog_id'].to_s.blank?
    validate_catalog_types!
    validate_body!(@payload['body'], max_length: catalog_body_limit, required: true, label: 'Message body')
    validate_examples!(@payload['body'], @payload['body_examples'], 'Message body')
    validate_body!(@payload['footer'], max_length: 60, required: false, label: 'Footer')
    fail!('Footer cannot contain variables') if variable_names(@payload['footer'].to_s).any?
    validate_mpm_header! if @payload['catalog_format'] == 'products' && @payload['product_template_type'] == 'mpm'
    validate_product_carousel_button! if @payload['catalog_format'] == 'product_carousel'
  end

  def validate_mpm_header!
    validate_text_header!
  end

  def validate_catalog_types!
    fail!('Invalid catalog template type') unless %w[catalog_template product_carousel products].include?(@payload['catalog_format'])
    invalid_product_type = @payload['catalog_format'] == 'products' && %w[spm mpm].exclude?(@payload['product_template_type'])
    fail!('Invalid product template type') if invalid_product_type
  end

  def catalog_body_limit
    return MAX_CARD_BODY_LENGTH if @payload['catalog_format'] == 'products' && @payload['product_template_type'] == 'spm'

    MAX_BODY_LENGTH
  end

  def validate_product_carousel_button!
    type = @payload['product_carousel_button_type']
    fail!('Invalid product carousel button type') unless %w[SPM URL].include?(type)
    return if type == 'SPM'

    button = @payload['product_carousel_button']
    fail!('Product carousel URL button is missing') unless button.is_a?(Hash)
    text = button['text'].to_s.strip
    fail!('Product carousel URL button text is invalid') if text.blank? || text.length > MAX_BUTTON_TEXT_LENGTH
    validate_url_button!(button.merge('value' => button['url']), 0)
  end

  private

  def validate_identity!
    validate_name!
    validate_language_and_category!
    fail!('Template parameter format is invalid') unless valid_parameter_format?
    return if @payload['category'] == 'AUTHENTICATION'
    return if @payload['template_format'] == 'standard'

    fail!('Carousel templates must use the MARKETING category') unless @payload['category'] == 'MARKETING'
  end

  def validate_name!
    fail!('Template name is invalid') unless TEMPLATE_NAME_PATTERN.match?(@payload['name'].to_s)
    fail!('Template name is too long') if @payload['name'].to_s.length > 512
  end

  def validate_language_and_category!
    fail!('Template language is invalid') unless ALLOWED_LANGUAGES.include?(@payload['language'])
    fail!('Template category is invalid') unless %w[MARKETING UTILITY AUTHENTICATION].include?(@payload['category'])
  end

  def valid_parameter_format?
    %w[POSITIONAL NAMED].include?(parameter_format)
  end

  def validate_cards!
    cards = @payload['cards']
    fail!("Carousel templates require between #{MIN_CARDS} and #{MAX_CARDS} cards") unless valid_card_count?(cards)
    fail!('Every carousel card requires a media file') unless @media_files.length == cards.length && @media_files.all?
    fail!('Carousel media type is invalid') unless ALLOWED_MEDIA_TYPES.key?(@payload['media_type'])
  end

  def valid_card_count?(cards)
    cards.is_a?(Array) && cards.length.between?(MIN_CARDS, MAX_CARDS)
  end

  def validate_button_types!
    types = @payload['button_types']
    valid = types.is_a?(Array) && types.length <= 2 && types.uniq.length == types.length && (types - ALLOWED_BUTTON_TYPES).empty?
    fail!('Carousel button types are invalid') unless valid
  end

  def validate_card!(card, index)
    label = "Card #{index + 1} body"
    validate_media!(@media_files[index])
    validate_body!(card['body'], max_length: MAX_CARD_BODY_LENGTH, required: @payload['card_text_enabled'], label: label)
    validate_card_body_details!(card, label)
    @payload['button_types'].each { |type| validate_button!(card.dig('buttons', type), type, index) }
  end

  def validate_card_body_details!(card, label)
    return unless @payload['card_text_enabled']

    validate_examples!(card['body'], card['body_examples'], label)
    fail!("#{label} has too many line breaks") if card['body'].to_s.count("\n") > MAX_CARD_LINE_BREAKS
  end

  def validate_media!(file)
    rules = ALLOWED_MEDIA_TYPES.fetch(@payload['media_type'])
    fail!('Carousel media file type is invalid') unless rules[:content_types].include?(file.content_type)
    fail!('Carousel media file is too large') if file.size > rules[:max_size]
  end

  def validate_body!(text, max_length:, required:, label:)
    variable_validator.validate_text!(text, max_length: max_length, required: required, label: label)
  end

  def validate_examples!(text, examples, label)
    variable_validator.validate_examples!(text, examples, label)
  end

  def validate_button!(button, type, card_index)
    fail!("Card #{card_index + 1} button is missing") unless button.is_a?(Hash)
    text = button['text'].to_s.strip
    fail!("Card #{card_index + 1} button text is invalid") if text.blank? || text.length > MAX_BUTTON_TEXT_LENGTH

    validate_url_button!(button, card_index) if type == 'URL'
    validate_phone_number!(button['value'], card_index) if type == 'PHONE_NUMBER'
  end

  def validate_url_button!(button, card_index)
    variable_validator.validate_url!(button['value'].to_s, button['example'], "Card #{card_index + 1} website URL")
  end

  def validate_phone_number!(value, card_index)
    fail!("Card #{card_index + 1} phone number is invalid") unless PHONE_NUMBER_PATTERN.match?(value.to_s)
  end

  def parameter_format
    (@payload['parameter_format'].presence || 'POSITIONAL').to_s.upcase
  end

  def variable_validator
    @variable_validator ||= Whatsapp::TemplateVariableValidator.new(@payload)
  end

  def fail!(message)
    raise Whatsapp::TemplateCreationService::ValidationError, message
  end
end

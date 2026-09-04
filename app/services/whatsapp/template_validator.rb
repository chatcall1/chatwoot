class Whatsapp::TemplateValidator
  ALLOWED_LANGUAGES = %w[ar en].freeze
  ALLOWED_MEDIA_TYPES = {
    'IMAGE' => { content_types: %w[image/jpeg image/png], max_size: 5.megabytes },
    'VIDEO' => { content_types: %w[video/mp4 video/3gpp], max_size: 16.megabytes }
  }.freeze
  ALLOWED_BUTTON_TYPES = %w[QUICK_REPLY URL PHONE_NUMBER].freeze
  MAX_BODY_LENGTH = 1024
  MAX_CARD_BODY_LENGTH = 160
  MAX_BUTTON_TEXT_LENGTH = 25
  MAX_CARD_LINE_BREAKS = 2
  MAX_CARDS = 10
  MIN_CARDS = 2
  PHONE_NUMBER_PATTERN = /\A\+[1-9]\d{6,14}\z/
  TEMPLATE_NAME_PATTERN = /\A[a-z0-9_]+\z/
  VARIABLE_PATTERN = /\{\{(\d+)\}\}/

  def initialize(payload:, media_files:)
    @payload = payload
    @media_files = media_files
  end

  def validate!
    validate_identity!
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
    validate_flow_button!
  end

  def validate_standard_copy!
    validate_body!(@payload['footer'], max_length: 60, required: false, label: 'Footer')
    fail!('Footer cannot contain variables') if @payload['footer'].to_s.match?(VARIABLE_PATTERN)
    fail!('Flow templates only support no header or a text header') unless %w[none text].include?(@payload['header_type'])
    validate_body!(@payload['header_text'], max_length: 60, required: true, label: 'Header') if @payload['header_type'] == 'text'
    fail!('Flow template text headers cannot contain variables yet') if @payload['header_text'].to_s.match?(VARIABLE_PATTERN)
  end

  def validate_flow_button!
    button = @payload['button']
    fail!('Flow button is missing') unless button.is_a?(Hash) && button['type'] == 'FLOW'
    fail!('Flow button text is invalid') if button['text'].to_s.strip.blank? || button['text'].to_s.strip.length > MAX_BUTTON_TEXT_LENGTH
    fail!('A published Flow must be selected') if button['flow_id'].to_s.blank?
  end

  def validate_catalog!
    fail!('A catalog must be selected') if @payload['catalog_id'].to_s.blank?
    validate_catalog_types!
    validate_body!(@payload['body'], max_length: catalog_body_limit, required: true, label: 'Message body')
    validate_examples!(@payload['body'], @payload['body_examples'], 'Message body')
    validate_body!(@payload['footer'], max_length: 60, required: false, label: 'Footer')
    fail!('Footer cannot contain variables') if @payload['footer'].to_s.match?(VARIABLE_PATTERN)
    validate_product_carousel_button! if @payload['catalog_format'] == 'product_carousel'
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
    fail!('Template name is invalid') unless TEMPLATE_NAME_PATTERN.match?(@payload['name'].to_s)
    fail!('Template language is invalid') unless ALLOWED_LANGUAGES.include?(@payload['language'])
    fail!('Carousel templates must use the MARKETING category') unless @payload['category'] == 'MARKETING'
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
    value = text.to_s
    fail!("#{label} is required") if required && value.blank?
    fail!("#{label} is too long") if value.length > max_length
    validate_variables!(value, label)
  end

  def validate_variables!(text, label, allow_at_end: false)
    validate_variable_syntax!(text, label)

    indexes = text.scan(VARIABLE_PATTERN).flatten.map(&:to_i)
    return if indexes.empty?

    fail!("#{label} variables must be sequential") unless indexes.uniq == (1..indexes.uniq.length).to_a
    fail!("#{label} cannot start or end with a variable") if invalid_variable_boundary?(text, allow_at_end: allow_at_end)
    fail!("#{label} cannot contain adjacent variables") if text.match?(/\}\}\s*\{\{/)
  end

  def validate_variable_syntax!(text, label)
    fail!("#{label} contains an invalid variable") if text.gsub(VARIABLE_PATTERN, '').match?(/\{\{|\}\}/)
  end

  def invalid_variable_boundary?(text, allow_at_end:)
    return true if text.match?(/\A\s*\{\{\d+\}\}/)

    !allow_at_end && text.match?(/\{\{\d+\}\}\s*\z/)
  end

  def validate_examples!(text, examples, label)
    count = text.to_s.scan(VARIABLE_PATTERN).flatten.map(&:to_i).uniq.length
    valid = examples.is_a?(Array) && examples.length == count && examples.all? { |example| example.to_s.strip.present? }
    fail!("#{label} requires an example for every variable") unless valid
  end

  def validate_button!(button, type, card_index)
    fail!("Card #{card_index + 1} button is missing") unless button.is_a?(Hash)
    text = button['text'].to_s.strip
    fail!("Card #{card_index + 1} button text is invalid") if text.blank? || text.length > MAX_BUTTON_TEXT_LENGTH

    validate_url_button!(button, card_index) if type == 'URL'
    validate_phone_number!(button['value'], card_index) if type == 'PHONE_NUMBER'
  end

  def validate_url_button!(button, card_index)
    value = button['value'].to_s
    validate_variables!(value, "Card #{card_index + 1} website URL", allow_at_end: true)
    validate_dynamic_url!(value, button['example'], card_index)
    uri = URI.parse(value.gsub(VARIABLE_PATTERN, 'example'))
    valid = uri.is_a?(URI::HTTP) && uri.host.present? && %w[http https].include?(uri.scheme)
    fail!("Card #{card_index + 1} website URL is invalid") unless valid
  rescue URI::InvalidURIError
    fail!("Card #{card_index + 1} website URL is invalid")
  end

  def validate_dynamic_url!(value, example, card_index)
    variables = value.scan(VARIABLE_PATTERN)
    return if variables.empty?

    fail!("Card #{card_index + 1} website URL variable must appear once at the end") unless variables.one? && value.end_with?('{{1}}')
    fail!("Card #{card_index + 1} website URL requires a variable example") if example.to_s.strip.blank?
  end

  def validate_phone_number!(value, card_index)
    fail!("Card #{card_index + 1} phone number must use international format") unless PHONE_NUMBER_PATTERN.match?(value.to_s)
  end

  def fail!(message)
    raise Whatsapp::TemplateCreationService::ValidationError, message
  end
end

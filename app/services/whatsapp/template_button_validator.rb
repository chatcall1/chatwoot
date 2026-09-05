class Whatsapp::TemplateButtonValidator
  ALLOWED_TYPES = %w[QUICK_REPLY URL PHONE_NUMBER FLOW COPY_CODE].freeze
  MAX_TEXT_LENGTH = 25
  PHONE_NUMBER_PATTERN = /\A[+\d][\d\s().-]{5,19}\z/

  def initialize(payload:, variable_validator:)
    @payload = payload
    @variable_validator = variable_validator
  end

  def validate!
    buttons = @payload['buttons'] || []
    fail!('Template buttons are invalid') unless buttons.is_a?(Array) && buttons.length <= 10
    validate_type_limits!(buttons)
    validate_quick_reply_grouping!(buttons)
    buttons.each_with_index { |button, index| validate_button!(button, index) }
  end

  private

  def validate_type_limits!(buttons)
    { 'URL' => 2, 'PHONE_NUMBER' => 1, 'FLOW' => 1, 'COPY_CODE' => 1 }.each do |type, limit|
      next unless count(buttons, type) > limit

      quantity = limit == 1 ? 'one' : 'up to two'
      fail!("A template supports #{quantity} #{type.downcase.tr('_', ' ')} button#{'s' if limit > 1}")
    end
  end

  def count(buttons, type)
    buttons.count { |button| button['type'] == type }
  end

  def validate_quick_reply_grouping!(buttons)
    groups = buttons.chunk { |button| button['type'] == 'QUICK_REPLY' }.map(&:first)
    fail!('Quick reply buttons must be grouped together') if groups.count(true) > 1
  end

  def validate_button!(button, index)
    fail!('Template button is invalid') unless button.is_a?(Hash) && ALLOWED_TYPES.include?(button['type'])
    return validate_copy_code!(button) if button['type'] == 'COPY_CODE'

    validate_text!(button)
    validate_destination!(button, index)
    validate_app_deep_link!(button) if button['app_deep_link'].present?
  end

  def validate_copy_code!(button)
    example = button['example'].to_s.strip
    fail!('Copy code example is required') if example.blank?
    fail!('Copy code example cannot exceed 20 characters') if example.length > 20
  end

  def validate_text!(button)
    text = button['text'].to_s.strip
    fail!('Template button text is invalid') if text.blank? || text.length > MAX_TEXT_LENGTH
  end

  def validate_destination!(button, index)
    @variable_validator.validate_url!(button['value'].to_s, button['example'], "Button #{index + 1} website URL") if button['type'] == 'URL'
    validate_phone_number!(button['value'], index) if button['type'] == 'PHONE_NUMBER'
    fail!('A published Flow must be selected') if button['type'] == 'FLOW' && button['flow_id'].to_s.blank?
  end

  def validate_phone_number!(value, index)
    fail!("Button #{index + 1} phone number is invalid") unless PHONE_NUMBER_PATTERN.match?(value.to_s)
  end

  def validate_app_deep_link!(button)
    fail!('Android deep links require a marketing URL button') unless @payload['category'] == 'MARKETING' && button['type'] == 'URL'

    deep_link = button['app_deep_link']
    fail!('Meta app ID is invalid') unless deep_link['meta_app_id'].to_s.match?(/\A\d+\z/)
    fail!('Android deep link is invalid') unless deep_link['android_deep_link'].to_s.match?(%r{\A[a-z][a-z0-9+.-]*://}i)
    validate_http_url!(deep_link['android_fallback_playstore_url'], 'Android fallback URL')
  end

  def validate_http_url!(value, label)
    uri = URI.parse(value.to_s)
    fail!("#{label} is invalid") unless uri.is_a?(URI::HTTP) && uri.host.present? && %w[http https].include?(uri.scheme)
  rescue URI::InvalidURIError
    fail!("#{label} is invalid")
  end

  def fail!(message)
    raise Whatsapp::TemplateCreationService::ValidationError, message
  end
end

class Whatsapp::AuthenticationTemplateBuilder
  OTP_TYPES = %w[COPY_CODE ONE_TAP ZERO_TAP].freeze
  APP_OTP_TYPES = %w[ONE_TAP ZERO_TAP].freeze
  PACKAGE_PATTERN = /\A(?:[A-Za-z][A-Za-z0-9_]*\.)+[A-Za-z][A-Za-z0-9_]*\z/
  SIGNATURE_PATTERN = %r{\A[A-Za-z0-9+/=]{11}\z}

  def initialize(payload)
    @payload = payload
    @settings = payload['authentication']
  end

  def validate!
    fail!('Authentication settings are missing') unless @settings.is_a?(Hash)
    fail!('Invalid authentication OTP type') unless OTP_TYPES.include?(otp_type)

    validate_integer(@settings['code_expiration_minutes'], 'Code expiration', 1..90)
    validate_integer(@settings['message_send_ttl_seconds'], 'Message time-to-live', 30..900)
    validate_button_text(@settings['copy_code_text'], 'Copy code button text')
    validate_button_text(@settings['autofill_text'], 'Autofill button text')
    validate_apps if APP_OTP_TYPES.include?(otp_type)
    fail!('Zero-tap terms must be accepted') if otp_type == 'ZERO_TAP' && @settings['zero_tap_terms_accepted'] != true
  end

  def build
    components = [{ type: 'BODY', add_security_recommendation: @settings['add_security_recommendation'] == true }]
    components << expiration_component if @settings['code_expiration_minutes'].present?
    components << buttons_component

    { name: @payload['name'], language: @payload['language'], category: 'AUTHENTICATION', components: components }.tap do |body|
      body[:message_send_ttl_seconds] = @settings['message_send_ttl_seconds'] if @settings['message_send_ttl_seconds'].present?
    end
  end

  private

  def otp_type
    @settings['otp_type']
  end

  def expiration_component
    { type: 'FOOTER', code_expiration_minutes: @settings['code_expiration_minutes'] }
  end

  def buttons_component
    button = { type: 'OTP', otp_type: otp_type }
    button[:text] = @settings['copy_code_text'] if @settings['copy_code_text'].present?
    button[:autofill_text] = @settings['autofill_text'] if @settings['autofill_text'].present?
    button[:supported_apps] = @settings.fetch('supported_apps') if APP_OTP_TYPES.include?(otp_type)
    button[:zero_tap_terms_accepted] = true if otp_type == 'ZERO_TAP'
    { type: 'BUTTONS', buttons: [button] }
  end

  def validate_integer(value, label, range)
    return if value.nil?

    integer = Integer(value, exception: false)
    fail!("#{label} is invalid") unless integer && range.cover?(integer)
  end

  def validate_button_text(value, label)
    fail!("#{label} is too long") if value.to_s.length > 25
  end

  def validate_apps
    apps = @settings['supported_apps']
    fail!('At least one supported Android app is required') unless apps.is_a?(Array) && apps.any?

    apps.each do |app|
      fail!('Android package name is invalid') unless PACKAGE_PATTERN.match?(app['package_name'].to_s)
      fail!('App signing key hash is invalid') unless SIGNATURE_PATTERN.match?(app['signature_hash'].to_s)
    end
  end

  def fail!(message)
    raise Whatsapp::TemplateCreationService::ValidationError, message
  end
end

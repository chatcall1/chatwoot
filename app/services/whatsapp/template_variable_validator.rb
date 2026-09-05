class Whatsapp::TemplateVariableValidator
  POSITIONAL_VARIABLE_PATTERN = /\{\{(\d+)\}\}/
  NAMED_VARIABLE_PATTERN = /\{\{([a-z][a-z_]*)\}\}/

  def initialize(payload)
    @payload = payload
  end

  def validate_text!(text, max_length:, required:, label:)
    value = text.to_s
    fail!("#{label} is required") if required && value.blank?
    fail!("#{label} is too long") if value.length > max_length
    validate_variables!(value, label)
  end

  def validate_examples!(text, examples, label)
    names = variable_names(text.to_s).uniq
    valid = named_parameters? ? valid_named_examples?(names, examples) : valid_positional_examples?(names, examples)
    fail!("#{label} requires an example for every variable") unless valid
  end

  def validate_url!(value, example, label)
    validate_variables!(value, label, allow_at_end: true)
    validate_dynamic_url!(value, example, label)
    uri = URI.parse(value.gsub(variable_pattern, 'example'))
    fail!("#{label} is invalid") unless uri.is_a?(URI::HTTP) && uri.host.present? && %w[http https].include?(uri.scheme)
  rescue URI::InvalidURIError
    fail!("#{label} is invalid")
  end

  def variable_names(text)
    text.scan(variable_pattern).flatten
  end

  private

  def validate_variables!(text, label, allow_at_end: false)
    fail!("#{label} contains an invalid variable") if text.gsub(variable_pattern, '').match?(/\{\{|\}\}/)
    names = variable_names(text)
    return if names.empty?

    validate_variable_order!(names, label)
    fail!("#{label} cannot start or end with a variable") if invalid_variable_boundary?(text, allow_at_end: allow_at_end)
    fail!("#{label} cannot contain adjacent variables") if text.match?(/\}\}\s*\{\{/)
  end

  def validate_variable_order!(names, label)
    if named_parameters?
      fail!("#{label} named variables must be unique") if names.uniq.length != names.length
      return
    end

    numeric_indexes = names.map(&:to_i)
    fail!("#{label} variables must be sequential") unless numeric_indexes.uniq == (1..numeric_indexes.uniq.length).to_a
  end

  def invalid_variable_boundary?(text, allow_at_end:)
    boundary_pattern = named_parameters? ? '[a-z][a-z_]*' : '\\d+'
    return true if text.match?(/\A\s*\{\{#{boundary_pattern}\}\}/)

    !allow_at_end && text.match?(/\{\{#{boundary_pattern}\}\}\s*\z/)
  end

  def validate_dynamic_url!(value, example, label)
    variables = variable_names(value)
    return if variables.empty?

    placeholder = "{{#{variables.first}}}"
    fail!("#{label} variable must appear once at the end") unless variables.one? && value.end_with?(placeholder)
    fail!("#{label} requires a variable example") if example.to_s.strip.blank?
  end

  def valid_named_examples?(names, examples)
    examples.is_a?(Hash) && names.all? { |name| examples[name].to_s.strip.present? }
  end

  def valid_positional_examples?(names, examples)
    examples.is_a?(Array) && examples.length == names.length && examples.all? { |example| example.to_s.strip.present? }
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

  def fail!(message)
    raise Whatsapp::TemplateCreationService::ValidationError, message
  end
end

class BotFlows::MetaNodeValidator
  TYPES = %w[location location_request contact sticker reaction cta_url carousel].freeze

  def initialize(node)
    @node = node
    @data = node['data'].to_h
    @errors = []
  end

  def errors
    raise ArgumentError, "Unsupported Meta node type: #{node['type']}" unless TYPES.include?(node['type'])

    send("validate_#{node['type']}")
    @errors
  end

  private

  attr_reader :node, :data

  def validate_location
    numeric_range('latitude', -90..90)
    numeric_range('longitude', -180..180)
  end

  def validate_location_request
    length_between('location request body', data['body'], 1..1024)
  end

  def validate_contact
    @errors << 'contact formatted name is required' if data.dig('name', 'formatted_name').blank?
    @errors << 'contact birthday must use YYYY-MM-DD' if data['birthday'].present? && !valid_date?(data['birthday'])
    validate_contact_emails
    validate_contact_urls
  end

  def validate_contact_emails
    invalid = Array(data['emails']).any? { |item| !URI::MailTo::EMAIL_REGEXP.match?(item['email'].to_s) }
    @errors << 'contact email is invalid' if invalid
  end

  def validate_contact_urls
    Array(data['urls']).each { |item| validate_https_url(item['url'], 'contact URL') }
  end

  def validate_sticker
    @errors.concat(BotFlows::MediaValidator.new(node).errors)
    blob = ActiveStorage::Blob.find_signed(data['blobSignedId'])
    @errors << 'static sticker exceeds 100 KB' if blob && !data['animated'] && blob.byte_size > 100.kilobytes
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end

  def validate_reaction
    @errors << 'reaction must contain exactly one emoji' unless data['emoji'].to_s.scan(/\X/).one?
  end

  def validate_cta_url
    length_between('CTA body', data['body'], 1..1024)
    length_between('CTA button text', data['buttonText'], 1..20)
    @errors << 'CTA footer cannot exceed 60 characters' if data['footer'].to_s.length > 60
    validate_https_url(data['url'], 'CTA URL')
    validate_header
  end

  def validate_carousel
    cards = Array(data['cards'])
    length_between('carousel body', data['body'], 1..1024)
    @errors << 'carousel must contain between 2 and 10 cards' unless cards.length.between?(2, 10)
    cards.each { |card| validate_carousel_card(card) }
    validate_carousel_consistency(cards)
  end

  def validate_carousel_card(card)
    type = card['headerType']
    @errors << 'carousel card media must be an image or video' unless %w[image video].include?(type)
    @errors.concat(BotFlows::MediaValidator.new('type' => type, 'data' => card).errors) if %w[image video].include?(type)
    @errors << 'carousel card body cannot exceed 160 characters' if card['body'].to_s.length > 160
    if data['buttonType'] == 'url'
      length_between('carousel card button text', card['buttonText'], 1..20)
      validate_https_url(card['url'], 'carousel card URL')
    else
      validate_carousel_replies(card)
    end
  end

  def validate_carousel_replies(card)
    replies = Array(card['replies'])
    @errors << 'carousel card must contain between 1 and 3 quick replies' unless replies.length.between?(1, 3)
    @errors << 'carousel quick reply titles must contain between 1 and 20 characters' unless replies.all? do |reply|
      reply['title'].to_s.length.between?(1, 20)
    end
    return if replies.pluck('id').all?(&:present?) && replies.pluck('id').uniq.length == replies.length

    @errors << 'carousel quick reply IDs must be present and unique'
  end

  def validate_carousel_consistency(cards)
    @errors << 'carousel button type is not supported' unless %w[url quick_reply].include?(data['buttonType'])
    return unless data['buttonType'] == 'quick_reply'

    counts = cards.map { |card| Array(card['replies']).length }
    @errors << 'all carousel cards must use the same number of quick replies' unless counts.uniq.one?
    ids = cards.flat_map { |card| Array(card['replies']).pluck('id') }
    @errors << 'carousel quick reply IDs must be unique across all cards' unless ids.uniq.length == ids.length
  end

  def validate_header
    type = data['headerType'].presence || 'none'
    @errors << 'CTA header type is not supported' unless %w[none text image video document].include?(type)
    length_between('CTA text header', data['headerText'], 1..60) if type == 'text'
    return unless %w[image video document].include?(type)

    media_node = { 'type' => type, 'data' => { 'blobSignedId' => data['headerBlobSignedId'] } }
    @errors.concat(BotFlows::MediaValidator.new(media_node).errors)
  end

  def numeric_range(key, range)
    number = Float(data[key], exception: false)
    @errors << "#{key} is invalid" unless number && range.cover?(number)
  end

  def length_between(label, value, range)
    @errors << "#{label} is required or has an invalid length" unless range.cover?(value.to_s.length)
  end

  def validate_https_url(value, label)
    uri = URI.parse(value.to_s)
    @errors << "#{label} must be a valid HTTPS URL" unless uri.is_a?(URI::HTTPS) && uri.host.present?
  rescue URI::InvalidURIError
    @errors << "#{label} must be a valid HTTPS URL"
  end

  def valid_date?(value)
    Date.iso8601(value.to_s)
    true
  rescue Date::Error
    false
  end
end

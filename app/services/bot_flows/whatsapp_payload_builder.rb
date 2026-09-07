class BotFlows::WhatsappPayloadBuilder
  PAYLOAD_TYPES = BotFlows::MetaNodeValidator::TYPES.freeze

  def initialize(message)
    @message = message
    @node = message.content_attributes.fetch('bot_flow_whatsapp_node').deep_stringify_keys
  end

  def call
    type = node.fetch('type')
    raise ArgumentError, "Unsupported WhatsApp node type: #{type}" unless PAYLOAD_TYPES.include?(type)

    send("#{type}_payload")
  end

  private

  attr_reader :message, :node

  def data = node.fetch('data')

  def location_payload
    location = data.slice('name', 'address').compact_blank
                   .merge(latitude: Float(data['latitude']), longitude: Float(data['longitude']))
    { type: 'location', location: location }
  end

  def location_request_payload
    {
      type: 'interactive',
      interactive: { type: 'location_request_message', body: { text: data['body'] }, action: { name: 'send_location' } }
    }
  end

  def reaction_payload
    { type: 'reaction', reaction: { message_id: node['triggerSourceId'], emoji: data['emoji'] } }
  end

  def sticker_payload
    { type: 'sticker', sticker: { link: blob_url(data['blobSignedId']) } }
  end

  def contact_payload
    { type: 'contacts', contacts: [contact] }
  end

  def contact
    {
      name: contact_name,
      birthday: data['birthday'].presence,
      org: contact_organization,
      phones: contact_collection('phones', %w[phone type wa_id]),
      emails: contact_collection('emails', %w[email type]),
      urls: contact_collection('urls', %w[url type]),
      addresses: contact_collection('addresses', %w[street city state zip country country_code type])
    }.compact_blank
  end

  def contact_name = data.fetch('name').slice('formatted_name', 'first_name', 'middle_name', 'last_name', 'prefix', 'suffix').compact_blank

  def contact_organization = data.fetch('org', {}).slice('company', 'department', 'title').compact_blank

  def contact_collection(key, fields) = Array(data[key]).map { |item| item.slice(*fields).compact_blank }

  def cta_url_payload
    payload = {
      type: 'cta_url', body: { text: data['body'] },
      action: { name: 'cta_url', parameters: { display_text: data['buttonText'], url: data['url'] } }
    }
    payload[:header] = interactive_header if data['headerType'].present? && data['headerType'] != 'none'
    payload[:footer] = { text: data['footer'] } if data['footer'].present?
    { type: 'interactive', interactive: payload }
  end

  def carousel_payload
    cards = Array(data['cards']).map.with_index do |card, index|
      card_payload = {
        card_index: index, type: 'cta_url',
        header: { 'type' => card['headerType'], card['headerType'] => { link: blob_url(card['blobSignedId']) } },
        body: ({ text: card['body'] } if card['body'].present?)
      }.compact
      card_payload[:action] = carousel_card_action(card)
      card_payload
    end
    { type: 'interactive', interactive: { type: 'carousel', body: { text: data['body'] }, action: { cards: cards } } }
  end

  def carousel_card_action(card)
    return { name: 'cta_url', parameters: { display_text: card['buttonText'], url: card['url'] } } if data['buttonType'] == 'url'

    buttons = Array(card['replies']).map do |reply|
      { type: 'quick_reply', quick_reply: { id: reply['id'], title: reply['title'] } }
    end
    { buttons: buttons }
  end

  def interactive_header
    type = data['headerType']
    return { type: 'text', text: data['headerText'] } if type == 'text'

    { 'type' => type, type => { link: blob_url(data['headerBlobSignedId']) } }
  end

  def blob_url(signed_id)
    ActiveStorage::Current.url_options = Rails.application.routes.default_url_options if ActiveStorage::Current.url_options.blank?
    ActiveStorage::Blob.find_signed!(signed_id).url
  end
end

#######################################
# To create a whatsapp provider
# - Inherit this as the base class.
# - Implement `send_message` method in your child class.
# - Implement `send_template_message` method in your child class.
# - Implement `sync_templates` method in your child class.
# - Implement `validate_provider_config` method in your child class.
# - Use Childclass.new(whatsapp_channel: channel).perform.
######################################

class Whatsapp::Providers::BaseService
  pattr_initialize [:whatsapp_channel!]

  def send_message(_phone_number, _message)
    raise 'Overwrite this method in child class'
  end

  def send_template(_phone_number, _template_info, _message)
    raise 'Overwrite this method in child class'
  end

  def sync_template
    raise 'Overwrite this method in child class'
  end

  def validate_provider_config
    raise 'Overwrite this method in child class'
  end

  def error_message
    raise 'Overwrite this method in child class'
  end

  def process_response(response, message)
    parsed_response = response.parsed_response
    if response.success? && parsed_response['error'].blank?
      parsed_response['messages'].first['id']
    else
      handle_error(response, message)
      nil
    end
  end

  def perform_bot_flow_request(message, url, recipient)
    payload = BotFlows::WhatsappPayloadBuilder.new(message).call
    response = HTTParty.post(url, headers: api_headers, body: payload.merge(**recipient).to_json)
    process_response(response, message)
  end

  def handle_error(response, message)
    Rails.logger.error response.body
    return if message.blank?

    # https://developers.facebook.com/docs/whatsapp/cloud-api/support/error-codes/#sample-response
    error_message = error_message(response)
    return if error_message.blank?

    message.external_error = error_message
    message.status = :failed
    message.save!
  end

  # WhatsApp coexistence / username migration: a contact may become addressable only by a Business-Scoped
  # User ID (BSUID, e.g. "BR.123..."), with no phone number available. The Cloud API requires a BSUID to be
  # passed in the `recipient` field (with recipient_type: individual), NOT in `to`. Passing a BSUID in `to`
  # returns HTTP 200 with a message id but the message is silently dropped: the "CC." prefix is stripped and
  # the remainder is treated as a phone number (wa_id), which never resolves. Phone numbers keep using `to`.
  # See: https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids/
  def recipient_params(identifier)
    if identifier.to_s.match?(RegexHelper::WHATSAPP_BSUID_REGEX)
      { recipient_type: 'individual', recipient: identifier }
    else
      { to: identifier }
    end
  end

  def create_buttons(items)
    buttons = []
    items.each do |item|
      button = { :type => 'reply', 'reply' => { 'id' => item['value'], 'title' => item['title'] } }
      buttons << button
    end
    buttons
  end

  def create_rows(items)
    rows = []
    items.each do |item|
      row = {
        'id' => item['value'] || item[:value],
        'title' => item['title'] || item[:title]
      }
      description = item_description(item)
      row['description'] = description if description.present?
      rows << row
    end
    rows
  end

  def create_payload(type, message_content, action)
    {
      'type': type,
      'body': {
        'text': message_content
      },
      'action': action
    }
  end

  def create_payload_based_on_items(message)
    @interactive_details = message.content_attributes['bot_flow_interactive'].to_h
    items = message.content_attributes['items']
    explicit_type = message.content_attributes['bot_flow_interactive_type']

    if explicit_type == 'buttons'
      create_button_payload(message)
    elsif explicit_type == 'list' || (explicit_type.blank? && use_list_payload?(items))
      create_list_payload(message)
    else
      create_button_payload(message)
    end
  end

  def use_list_payload?(items)
    items.length > 3 || items.any? { |item| item_description(item).present? }
  end

  def item_description(item)
    item['description'] || item[:description] || @interactive_details&.dig('descriptions', item['value'] || item[:value])
  end

  def create_button_payload(message)
    buttons = create_buttons(message.content_attributes['items'])
    json_hash = { 'buttons' => buttons }
    decorate_interactive_payload(create_payload('button', message.outgoing_content, JSON.generate(json_hash)))
  end

  def create_list_payload(message)
    sections = create_list_sections(message.content_attributes['items'])
    button_text = @interactive_details['button_text'].presence || I18n.t('conversations.messages.whatsapp.list_button_label')
    json_hash = { :button => button_text, 'sections' => sections }
    decorate_interactive_payload(create_payload('list', message.outgoing_content, JSON.generate(json_hash)))
  end

  def create_list_sections(items)
    configured = @interactive_details['sections']
    return [{ 'rows' => create_rows(items) }] if configured.blank?

    configured.map do |section|
      section_items = items.select { |item| section['row_ids'].include?(item['value']) }
      { 'title' => section['title'], 'rows' => create_rows(section_items) }
    end
  end

  def decorate_interactive_payload(payload)
    header_type = @interactive_details['header_type']
    if header_type == 'text' && @interactive_details['header_text'].present?
      payload[:header] = { type: 'text', text: @interactive_details['header_text'] }
    elsif %w[image video document].include?(header_type) && interactive_header_url.present?
      media = { link: interactive_header_url }
      media[:filename] = @interactive_details['header_filename'] if header_type == 'document'
      payload[:header] = { 'type' => header_type, header_type => media }
    end
    payload[:footer] = { text: @interactive_details['footer'] } if @interactive_details['footer'].present?
    payload
  end

  def interactive_header_url
    signed_id = @interactive_details['header_blob_signed_id']
    return if signed_id.blank?

    ActiveStorage::Current.url_options = Rails.application.routes.default_url_options if ActiveStorage::Current.url_options.blank?
    ActiveStorage::Blob.find_signed(signed_id)&.url
  end
end

Whatsapp::Providers::BaseService.prepend_mod_with('Whatsapp::Providers::BaseService')

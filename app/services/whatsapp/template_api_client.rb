class Whatsapp::TemplateApiClient
  def initialize(channel)
    @channel = channel
  end

  def upload_media!(file)
    session_response = create_upload_session(file)
    raise_api_error!(session_response, fallback: 'WhatsApp media upload failed') unless session_response.success?

    upload_response = upload_file(session_response['id'], file)
    raise_api_error!(upload_response, fallback: 'WhatsApp media upload failed') unless upload_response.success? && upload_response['h'].present?

    upload_response['h']
  ensure
    file.rewind if file.respond_to?(:rewind)
  end

  def create_template!(payload)
    response = HTTParty.post(message_templates_path, headers: json_headers, body: payload.to_json)
    raise_api_error!(response, fallback: 'WhatsApp template creation failed') unless response.success?

    response
  end

  private

  def create_upload_session(file)
    HTTParty.post(
      upload_sessions_path,
      headers: authorization_headers,
      query: { file_name: file.original_filename, file_length: file.size, file_type: file.content_type }
    )
  end

  def upload_file(session_id, file)
    HTTParty.post(
      "#{api_base_path}/#{api_version}/#{session_id}",
      headers: authorization_headers.merge('file_offset' => '0', 'Content-Type' => 'application/octet-stream'),
      body: file.read
    )
  end

  def raise_api_error!(response, fallback:)
    error = response.parsed_response.is_a?(Hash) ? response.parsed_response['error'] : nil
    message = error&.dig('error_user_msg') || error&.dig('message') || fallback
    details = error&.slice('code', 'error_subcode', 'type', 'error_user_title')
    raise Whatsapp::TemplateCreationService::ApiError.new(message, details: details)
  end

  def message_templates_path
    "#{api_base_path}/#{api_version}/#{@channel.provider_config['business_account_id']}/message_templates"
  end

  def upload_sessions_path
    app_id = GlobalConfigService.load('WHATSAPP_APP_ID', nil)
    raise Whatsapp::TemplateCreationService::ValidationError, 'WhatsApp App ID is not configured' if app_id.blank?

    "#{api_base_path}/#{api_version}/#{app_id}/uploads"
  end

  def json_headers
    authorization_headers.merge('Content-Type' => 'application/json')
  end

  def authorization_headers
    { 'Authorization' => "Bearer #{@channel.template_access_token}" }
  end

  def api_version
    @api_version ||= Whatsapp::ApiVersion.current
  end

  def api_base_path
    ENV.fetch('WHATSAPP_CLOUD_BASE_URL', 'https://graph.facebook.com')
  end
end

class Whatsapp::TemplateSyncService
  TEMPLATE_FIELDS = 'id,name,status,category,language,components,parameter_format,message_send_ttl_seconds'.freeze

  def initialize(channel)
    @channel = channel
  end

  def sync
    @channel.mark_message_templates_updated
    templates = fetch
    return if templates.blank?

    @channel.account.update_cache_key('inbox') if templates != @channel.message_templates
    # rubocop:disable Rails/SkipsModelValidations
    @channel.update_columns(message_templates: templates, message_templates_last_updated: Time.current)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def fetch(after: nil)
    response = HTTParty.get(message_templates_path, request_options(after))
    return failed_response(response) unless response.success?

    templates = response['data']
    next_cursor = response.dig('paging', 'cursors', 'after')
    next_cursor.present? ? templates + fetch(after: next_cursor) : templates
  end

  private

  def request_options(after)
    {
      headers: { 'Authorization' => "Bearer #{@channel.template_access_token}" },
      query: { fields: TEMPLATE_FIELDS }.tap { |query| query[:after] = after if after.present? }
    }
  end

  def failed_response(response)
    Rails.logger.warn(
      "[WHATSAPP] Template sync failed for account #{@channel.account_id} " \
      "inbox #{@channel.inbox&.id}: #{response.code} #{error_message(response)}"
    )
    []
  end

  def error_message(response)
    response.parsed_response.dig('error', 'message') if response.parsed_response.is_a?(Hash)
  end

  def message_templates_path
    base_url = ENV.fetch('WHATSAPP_CLOUD_BASE_URL', 'https://graph.facebook.com')
    api_version = Whatsapp::ApiVersion.current
    business_account_id = @channel.provider_config['business_account_id']
    "#{base_url}/#{api_version}/#{business_account_id}/message_templates"
  end
end

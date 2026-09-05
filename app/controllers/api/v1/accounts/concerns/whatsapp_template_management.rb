module Api::V1::Accounts::Concerns::WhatsappTemplateManagement
  extend ActiveSupport::Concern

  def create_message_template
    channel = whatsapp_channel
    unless channel.provider == 'whatsapp_cloud'
      return render status: :unprocessable_entity, json: { error: 'Template creation is only available for WhatsApp Cloud API channels' }
    end

    payload = JSON.parse(params.require(:template).to_s)
    media_files = template_media_files(payload)
    result = Whatsapp::TemplateCreationService.new(channel).create!(payload: payload, media_files: media_files)

    Channels::Whatsapp::TemplatesSyncJob.perform_later(channel)
    render json: { template: result }, status: :created
  rescue ActionController::ParameterMissing, JSON::ParserError, Whatsapp::TemplateCreationService::ValidationError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue Whatsapp::TemplateCreationService::ApiError => e
    render json: { error: e.message, details: e.details }, status: :unprocessable_entity
  end

  def product_catalogs
    channel = whatsapp_channel
    catalogs = Whatsapp::FacebookApiClient.new(channel.template_access_token).fetch_product_catalogs(
      channel.provider_config['business_account_id']
    )

    render json: { payload: catalogs['data'] || [] }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def template_media_files(payload)
    return [params[:header_media]].compact if payload['template_format'] == 'standard'

    Array(payload['cards']).each_index.map { |index| params["media_#{index}"] }
  end
end

module Api::V1::Accounts::Concerns::WhatsappAuthenticationTemplateManagement
  extend ActiveSupport::Concern

  def authentication_template_preview
    channel = whatsapp_channel
    result = Whatsapp::FacebookApiClient.new(channel.template_access_token).fetch_authentication_template_preview(
      channel.provider_config['business_account_id'],
      language: params.require(:language),
      add_security_recommendation: ActiveModel::Type::Boolean.new.cast(params[:add_security_recommendation]),
      code_expiration_minutes: params[:code_expiration_minutes]
    )
    render json: { payload: Array(result['data']).first }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end

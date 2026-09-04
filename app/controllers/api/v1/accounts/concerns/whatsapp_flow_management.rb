module Api::V1::Accounts::Concerns::WhatsappFlowManagement
  extend ActiveSupport::Concern

  def whatsapp_flows
    channel = whatsapp_channel
    flows = Whatsapp::FacebookApiClient.new(channel.template_access_token).fetch_flows(channel.provider_config['business_account_id'])
    render json: { payload: Array(flows['data']).select { |flow| flow['status'] == 'PUBLISHED' } }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end

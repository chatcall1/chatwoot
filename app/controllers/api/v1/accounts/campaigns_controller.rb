class Api::V1::Accounts::CampaignsController < Api::V1::Accounts::BaseController
  before_action :campaign, except: [:index, :create, :test, :audience_count]
  before_action :check_authorization

  def index
    @campaigns = Current.account.campaigns
  end

  def show; end

  def create
    @campaign = Current.account.campaigns.create!(campaign_params.merge(sender_id: Current.user.id))
    Campaigns::TriggerOneoffCampaignJob.perform_later(@campaign) if @campaign.scheduled_at <= Time.current
  end

  def audience_count
    preview_campaign = Current.account.campaigns.new(campaign_params.merge(sender_id: Current.user.id))
    preview_campaign.validate!
    render json: { count: Whatsapp::CampaignAudienceService.new(campaign: preview_campaign).count }
  end

  def test
    source_id = Whatsapp::TestTemplateService.new(account: Current.account, user: Current.user, params: test_params.to_h).perform
    render json: { source_id: source_id }
  rescue ArgumentError => e
    render json: { message: e.message }, status: :unprocessable_entity
  end

  def update
    @campaign.update!(campaign_params)
  end

  def destroy
    @campaign.destroy!
    head :ok
  end

  private

  def campaign
    @campaign ||= Current.account.campaigns.find_by(display_id: params[:id])
  end

  def campaign_params
    params.require(:campaign).permit(:title, :description, :message, :enabled, :trigger_only_during_business_hours, :inbox_id, :sender_id,
                                     :scheduled_at, audience: [:type, :id], trigger_rules: {}, template_params: {})
  end

  def test_params
    params.require(:campaign).permit(:inbox_id, :phone_number, template_params: {})
  end
end

class Api::V1::Accounts::BotFlowsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :ensure_flow_builder_enabled
  before_action :set_bot_flow, only: [:show, :update, :destroy, :publish, :unpublish, :executions, :retry_delivery]

  def index
    @bot_flows = Current.account.bot_flows.includes(:inbox).order(updated_at: :desc)
  end

  def show; end

  def create
    @bot_flow = Current.account.bot_flows.create!(bot_flow_params)
    BotFlows::TemplateMediaMaterializer.new(@bot_flow).call
    @bot_flow.synchronize_media_files!
  end

  def update
    @bot_flow.update!(bot_flow_params)
    BotFlows::TemplateMediaMaterializer.new(@bot_flow).call
    @bot_flow.synchronize_media_files!
  rescue ActiveRecord::StaleObjectError
    render json: { message: 'This flow was updated in another session. Reload it and try again.' }, status: :conflict
  end

  def destroy
    @bot_flow.destroy!
    head :ok
  end

  def publish
    @bot_flow.publish!
    render :show
  end

  def unpublish
    @bot_flow.unpublish!
    render :show
  end

  def executions
    @executions = @bot_flow.bot_flow_executions.includes(bot_flow_deliveries: :message).order(created_at: :desc).limit(50)
  end

  def retry_delivery
    delivery = BotFlowDelivery.joins(:bot_flow_execution)
                              .where(bot_flow_executions: { bot_flow_id: @bot_flow.id })
                              .find(params.require(:delivery_id))
    scheduled_at = Time.current
    delivery.with_lock do
      return render json: { message: 'This delivery cannot be retried.' }, status: :unprocessable_entity unless delivery.manually_retryable?

      delivery.update!(retry_scheduled_at: scheduled_at)
    end
    BotFlows::RetryDeliveryJob.perform_later(delivery.id, scheduled_at.iso8601(6))
    render json: { scheduled: true }, status: :accepted
  end

  private

  def set_bot_flow
    @bot_flow = Current.account.bot_flows.find(params[:id])
  end

  def bot_flow_params
    params.require(:bot_flow).permit(:name, :inbox_id, :lock_version, draft_definition: {})
  end

  def ensure_flow_builder_enabled
    return if Current.account.feature_enabled?(:flow_builder)

    render json: { message: 'Flow Builder is not enabled for this account.' }, status: :forbidden
  end
end

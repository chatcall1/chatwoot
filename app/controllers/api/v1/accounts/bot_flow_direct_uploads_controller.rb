class Api::V1::Accounts::BotFlowDirectUploadsController < ActiveStorage::DirectUploadsController
  include DeviseTokenAuth::Concerns::SetUserByToken
  include RequestExceptionHandler
  include EnsureCurrentAccountHelper

  around_action :handle_with_exception
  before_action :authenticate_user!
  before_action :current_account
  before_action :ensure_flow_builder_enabled

  private

  def ensure_flow_builder_enabled
    return if Current.account.feature_enabled?(:flow_builder)

    render json: { message: 'Flow Builder is not enabled for this account.' }, status: :forbidden
  end
end

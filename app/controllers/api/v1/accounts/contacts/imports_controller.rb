class Api::V1::Accounts::Contacts::ImportsController < Api::V1::Accounts::BaseController
  before_action :authorize_import

  def show
    import = Current.account.data_imports.find(params[:id])
    render json: {
      id: import.id,
      status: import.status,
      total_records: import.total_records,
      processed_records: import.processed_records,
      rejected_records: import.total_records.to_i - import.processed_records.to_i,
      has_failed_records: import.failed_records.attached?
    }
  end

  def failed_records
    import = Current.account.data_imports.find(params[:id])
    raise ActiveRecord::RecordNotFound unless import.failed_records.attached?

    send_data import.failed_records.download, filename: import.failed_records.filename.to_s, type: 'text/csv'
  end

  private

  def authorize_import
    authorize Contact, :import?
  end
end

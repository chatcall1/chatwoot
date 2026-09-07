class BotFlows::MediaSynchronizer
  def initialize(flow)
    @flow = flow
  end

  def call
    attach_required_blobs
    detach_unused_blobs
  end

  private

  attr_reader :flow

  def required_blobs
    @required_blobs ||= flow.required_media_signed_ids.filter_map do |signed_id|
      find_blob(signed_id)
    end.uniq(&:id)
  end

  def find_blob(signed_id)
    ActiveStorage::Blob.find_signed(signed_id)
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end

  def attach_required_blobs
    attached_ids = flow.media_files.blobs.ids
    required_blobs.reject { |blob| attached_ids.include?(blob.id) }.each { |blob| flow.media_files.attach(blob) }
  end

  def detach_unused_blobs
    required_ids = required_blobs.map(&:id)
    flow.media_files.attachments.includes(:blob).where.not(blob_id: required_ids).find_each do |attachment|
      blob = attachment.blob
      attachment.destroy!
      blob.purge_later unless blob.attachments.exists?
    end
  end
end

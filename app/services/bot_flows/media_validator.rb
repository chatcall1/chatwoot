class BotFlows::MediaValidator
  RULES = {
    'image' => { types: %w[image/jpeg image/png], max_size: 5.megabytes },
    'video' => { types: %w[video/mp4 video/3gpp], max_size: 16.megabytes },
    'document' => {
      types: %w[
        text/plain application/pdf application/msword application/vnd.ms-excel application/vnd.ms-powerpoint
        application/vnd.openxmlformats-officedocument.wordprocessingml.document
        application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
        application/vnd.openxmlformats-officedocument.presentationml.presentation
      ],
      max_size: 100.megabytes
    },
    'audio' => { types: %w[audio/aac audio/amr audio/mpeg audio/mp4 audio/ogg], max_size: 16.megabytes },
    'sticker' => { types: %w[image/webp], max_size: 500.kilobytes }
  }.freeze

  def initialize(node)
    @node = node
  end

  def errors
    return ["#{node['type']} message must contain an uploaded file"] if signed_id.blank?

    blob = ActiveStorage::Blob.find_signed(signed_id)
    return ["#{node['type']} uploaded file is invalid"] unless blob

    blob_errors(blob)
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    ["#{node['type']} uploaded file is invalid"]
  end

  private

  attr_reader :node

  def signed_id = node.dig('data', 'blobSignedId')

  def invalid_voice_message?(blob)
    node['type'] == 'audio' && node.dig('data', 'isVoiceMessage') && blob.content_type != 'audio/ogg'
  end

  def blob_errors(blob)
    rule = RULES.fetch(node['type'])
    [].tap do |errors|
      errors << "#{node['type']} file type is not supported" unless rule[:types].include?(blob.content_type)
      errors << "#{node['type']} file exceeds the supported size" if blob.byte_size > rule[:max_size]
      errors << 'voice messages must use an OGG/Opus audio file' if invalid_voice_message?(blob)
    end
  end
end

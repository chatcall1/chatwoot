class Whatsapp::TemplateCreationService
  class ValidationError < StandardError; end

  class ApiError < StandardError
    attr_reader :details

    def initialize(message, details: nil)
      super(message)
      @details = details
    end
  end

  def initialize(channel)
    @channel = channel
  end

  def create!(payload:, media_files:)
    @payload = payload
    @media_files = media_files
    Whatsapp::TemplateValidator.new(payload: @payload, media_files: @media_files).validate!

    api_client = Whatsapp::TemplateApiClient.new(@channel)
    handles = @media_files.compact.map { |file| api_client.upload_media!(file) }
    request_body = Whatsapp::TemplateRequestBuilder.new(@payload).build(handles)
    response = api_client.create_template!(request_body)
    storage_warning = persist_template_media_warning

    result = {
      id: response['id'],
      name: @payload['name'],
      status: response['status'] || 'PENDING',
      category: response['category'] || @payload['category'],
      language: @payload['language']
    }
    result[:warning] = storage_warning if storage_warning.present?
    result
  end

  private

  def persist_template_media_warning
    persist_template_media!
    nil
  rescue StandardError => e
    Rails.logger.error(
      '[WHATSAPP TEMPLATE] Meta accepted template but local media storage failed ' \
      "channel_id=#{@channel.id} template=#{@payload['name']} error=#{e.class}: #{e.message}"
    )
    'media_storage_failed'
  end

  def persist_template_media!
    return if @payload['catalog_format'].present? || @payload['category'] == 'AUTHENTICATION' || @media_files.empty?

    WhatsappTemplateMedia.transaction do
      @channel.template_media.where(template_name: @payload['name']).destroy_all
      @media_files.each_with_index do |file, card_index|
        media = @channel.template_media.create!(
          template_name: @payload['name'],
          card_index: card_index,
          media_type: (@payload['media_type'] || @payload['header_type']).downcase
        )
        media.file.attach(file)
      end
    end
  end
end

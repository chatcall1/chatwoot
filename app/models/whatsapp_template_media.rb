class WhatsappTemplateMedia < ApplicationRecord
  belongs_to :channel, class_name: 'Channel::Whatsapp', inverse_of: :template_media
  has_one_attached :file

  validates :template_name, :card_index, :media_type, presence: true
  validates :card_index, uniqueness: { scope: [:channel_id, :template_name] }

  def download_url
    ActiveStorage::Current.url_options ||= Rails.application.routes.default_url_options
    file.blob.url
  end
end

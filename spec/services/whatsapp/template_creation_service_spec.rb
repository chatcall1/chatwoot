require 'rails_helper'

RSpec.describe Whatsapp::TemplateCreationService do
  subject(:service) { described_class.new(channel) }

  let(:template_media) { instance_double(ActiveRecord::Associations::CollectionProxy) }
  let(:channel) { instance_double(Channel::Whatsapp, id: 7, template_media: template_media) }
  let(:payload) { { 'name' => 'order_update', 'language' => 'en_US', 'category' => 'UTILITY' } }
  let(:api_client) { instance_double(Whatsapp::TemplateApiClient) }

  before do
    allow(Whatsapp::TemplateValidator).to receive(:new).and_return(instance_double(Whatsapp::TemplateValidator, validate!: true))
    allow(Whatsapp::TemplateRequestBuilder).to receive(:new).and_return(
      instance_double(Whatsapp::TemplateRequestBuilder, build: { name: 'order_update' })
    )
    allow(Whatsapp::TemplateApiClient).to receive(:new).with(channel).and_return(api_client)
    allow(api_client).to receive(:create_template!).and_return('id' => 'meta-id', 'status' => 'PENDING')
  end

  it 'returns the accepted template response' do
    expect(service.create!(payload: payload, media_files: [])).to include(
      id: 'meta-id', name: 'order_update', status: 'PENDING', category: 'UTILITY', language: 'en_US'
    )
  end

  it 'returns a warning instead of failing after Meta accepts the template when local media storage fails' do
    file = instance_double(ActionDispatch::Http::UploadedFile)
    allow(api_client).to receive(:upload_media!).with(file).and_return('media-handle')
    allow(template_media).to receive(:where).and_return(template_media)
    allow(template_media).to receive(:destroy_all)
    allow(template_media).to receive(:create!).and_raise(ActiveStorage::IntegrityError)
    allow(WhatsappTemplateMedia).to receive(:transaction).and_yield

    expect(service.create!(payload: payload.merge('header_type' => 'IMAGE'), media_files: [file])).to include(
      id: 'meta-id', warning: 'media_storage_failed'
    )
  end
end

require 'rails_helper'

RSpec.describe BotFlows::WhatsappPayloadBuilder do
  subject(:payload) { builder.call }

  let(:message) { instance_double(Message, content_attributes: { 'bot_flow_whatsapp_node' => node }) }
  let(:builder) { described_class.new(message) }
  let(:node) { { 'type' => type, 'data' => data, 'triggerSourceId' => 'wamid.trigger' } }

  before do
    allow(builder).to receive(:blob_url).and_return('https://example.test/media')
  end

  context 'with a location node' do
    let(:type) { 'location' }
    let(:data) { { 'latitude' => '24.7136', 'longitude' => '46.6753', 'name' => 'الموقع' } }

    it { is_expected.to include(type: 'location', location: include(latitude: 24.7136, longitude: 46.6753)) }
  end

  context 'with a location request node' do
    let(:type) { 'location_request' }
    let(:data) { { 'body' => 'أرسل موقعك' } }

    it { is_expected.to include(type: 'interactive', interactive: include(type: 'location_request_message')) }
  end

  context 'with a contact node' do
    let(:type) { 'contact' }
    let(:data) do
      {
        'name' => { 'formatted_name' => 'أحمد' },
        'phones' => [{ 'phone' => '+966500000000', 'type' => 'CELL' }],
        'addresses' => [{ 'city' => 'الرياض', 'type' => 'WORK' }]
      }
    end

    it { is_expected.to include(type: 'contacts', contacts: [include(name: { 'formatted_name' => 'أحمد' })]) }
  end

  context 'with a sticker node' do
    let(:type) { 'sticker' }
    let(:data) { { 'blobSignedId' => 'signed-id' } }

    it { is_expected.to eq(type: 'sticker', sticker: { link: 'https://example.test/media' }) }
  end

  context 'with a reaction node' do
    let(:type) { 'reaction' }
    let(:data) { { 'emoji' => '👍' } }

    it { is_expected.to eq(type: 'reaction', reaction: { message_id: 'wamid.trigger', emoji: '👍' }) }
  end

  context 'with a CTA URL node' do
    let(:type) { 'cta_url' }
    let(:data) do
      {
        'body' => 'افتح الرابط', 'buttonText' => 'فتح', 'url' => 'https://example.com',
        'headerType' => 'image', 'headerBlobSignedId' => 'signed-id', 'footer' => 'تفاصيل'
      }
    end

    it do
      expect(payload).to include(
        type: 'interactive',
        interactive: include(type: 'cta_url', header: include('type' => 'image'), action: include(name: 'cta_url'))
      )
    end
  end

  context 'with a URL carousel node' do
    let(:type) { 'carousel' }
    let(:data) do
      {
        'body' => 'اختر بطاقة', 'buttonType' => 'url',
        'cards' => [{ 'headerType' => 'image', 'blobSignedId' => 'one', 'buttonText' => 'فتح', 'url' => 'https://example.com' }]
      }
    end

    it { is_expected.to include(type: 'interactive', interactive: include(type: 'carousel')) }
  end

  context 'with a quick reply carousel node' do
    let(:type) { 'carousel' }
    let(:data) do
      {
        'body' => 'اختر بطاقة', 'buttonType' => 'quick_reply',
        'cards' => [{ 'headerType' => 'video', 'blobSignedId' => 'one', 'replies' => [{ 'id' => 'reply-1', 'title' => 'اختيار' }] }]
      }
    end

    it do
      buttons = payload.dig(:interactive, :action, :cards, 0, :action, :buttons)
      expect(buttons).to eq([{ type: 'quick_reply', quick_reply: { id: 'reply-1', title: 'اختيار' } }])
    end
  end
end

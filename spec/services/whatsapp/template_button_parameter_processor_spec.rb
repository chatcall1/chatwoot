require 'rails_helper'

RSpec.describe Whatsapp::TemplateButtonParameterProcessor do
  let(:channel) { instance_double(Channel::Whatsapp, account_id: 2) }

  it 'uses the synchronized button index when a copy-code button follows a quick reply' do
    template = {
      'components' => [{
        'type' => 'BUTTONS',
        'buttons' => [{ 'type' => 'QUICK_REPLY' }, { 'type' => 'COPY_CODE' }]
      }]
    }
    result = described_class.new(
      channel: channel, template: template,
      processed_params: { 'buttons' => [{ 'type' => 'copy_code', 'parameter' => 'SAVE20' }] }
    ).call

    expect(result.first).to include(type: 'button', sub_type: 'copy_code', index: '1')
  end

  it 'builds a Flow action using the outgoing message identity' do
    template = {
      'components' => [{ 'type' => 'BUTTONS', 'buttons' => [{ 'type' => 'FLOW' }] }]
    }
    message = instance_double(Message, id: 45)
    result = described_class.new(channel: channel, template: template, processed_params: {}, message: message).call

    expect(result.first).to eq(
      type: 'button', sub_type: 'flow', index: '0',
      parameters: [{ type: 'action', action: { flow_token: 'chatwoot_2_45' } }]
    )
  end

  it 'duplicates the authentication code into the OTP button parameter' do
    template = { 'category' => 'AUTHENTICATION', 'components' => [] }
    result = described_class.new(
      channel: channel, template: template, processed_params: { 'body' => { '1' => '123456' } }
    ).call

    expect(result.first).to include(
      type: 'button', sub_type: 'url', index: '0', parameters: [{ type: 'text', text: '123456' }]
    )
  end
end

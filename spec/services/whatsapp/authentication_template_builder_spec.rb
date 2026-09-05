require 'rails_helper'

RSpec.describe Whatsapp::AuthenticationTemplateBuilder do
  let(:authentication) do
    {
      'otp_type' => 'COPY_CODE',
      'add_security_recommendation' => true,
      'code_expiration_minutes' => 10,
      'message_send_ttl_seconds' => 60,
      'copy_code_text' => 'Copy code',
      'supported_apps' => []
    }
  end
  let(:payload) do
    { 'name' => 'login_code', 'language' => 'en_US', 'category' => 'AUTHENTICATION', 'authentication' => authentication }
  end

  it 'builds Meta authentication components and preserves its authentication TTL' do
    builder = described_class.new(payload)

    expect { builder.validate! }.not_to raise_error
    expect(builder.build).to include(
      name: 'login_code', category: 'AUTHENTICATION', message_send_ttl_seconds: 60
    )
  end

  it 'rejects an authentication TTL outside Meta limits' do
    authentication['message_send_ttl_seconds'] = 901

    expect { described_class.new(payload).validate! }.to raise_error(
      Whatsapp::TemplateCreationService::ValidationError, 'Message time-to-live is invalid'
    )
  end
end

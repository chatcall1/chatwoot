require 'rails_helper'

RSpec.describe BotFlows::TemplateMediaMaterializer do
  let(:definition) do
    {
      'nodes' => [
        {
          'id' => 'interactive-1',
          'type' => 'interactive',
          'data' => { 'templateAsset' => 'demo_company_logo' }
        }
      ],
      'edges' => []
    }
  end
  let(:flow) { instance_double(BotFlow, draft_definition: definition) }
  let(:blob) do
    instance_double(
      ActiveStorage::Blob,
      signed_id: 'signed-logo',
      filename: ActiveStorage::Filename.new('demo-company-logo.png'),
      content_type: 'image/png',
      byte_size: 123
    )
  end

  it 'copies the template asset into the flow definition only when requested' do
    allow(ActiveStorage::Blob).to receive(:create_and_upload!).and_return(blob)
    expect(flow).to receive(:update!) do |draft_definition:|
      data = draft_definition.dig('nodes', 0, 'data')
      expect(data).not_to have_key('templateAsset')
      expect(data['headerBlobSignedId']).to eq('signed-logo')
      expect(data['headerContentType']).to eq('image/png')
    end

    described_class.new(flow).call
  end
end

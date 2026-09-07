class BotFlows::TemplateMediaMaterializer
  ASSETS = {
    'demo_company_logo' => Rails.root.join('app/assets/images/flow_builder/demo-company-logo.svg')
  }.freeze

  def initialize(flow)
    @flow = flow
  end

  def call
    definition = flow.draft_definition.deep_dup
    template_nodes = definition.fetch('nodes', []).select { |node| ASSETS.key?(node.dig('data', 'templateAsset')) }
    return if template_nodes.empty?

    created_blobs = template_nodes.map { |node| materialize(node) }
    flow.update!(draft_definition: definition)
  rescue StandardError
    created_blobs&.each(&:purge_later)
    raise
  end

  private

  attr_reader :flow

  def materialize(node)
    asset = node['data'].delete('templateAsset')
    path = ASSETS.fetch(asset)
    converted = ImageProcessing::MiniMagick.source(path).convert('png').call
    blob = ActiveStorage::Blob.create_and_upload!(
      io: converted, filename: 'demo-company-logo.png', content_type: 'image/png'
    )
    node['data'].merge!(
      'headerBlobSignedId' => blob.signed_id,
      'headerFilename' => blob.filename.to_s,
      'headerContentType' => blob.content_type,
      'headerByteSize' => blob.byte_size
    )
    blob
  end
end

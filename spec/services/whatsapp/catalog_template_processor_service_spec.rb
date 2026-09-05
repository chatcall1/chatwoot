require 'rails_helper'

RSpec.describe Whatsapp::CatalogTemplateProcessorService do
  let(:channel) do
    instance_double(
      Channel::Whatsapp,
      id: 7,
      template_access_token: 'token',
      provider_config: { 'business_account_id' => 'waba-id' }
    )
  end

  before do
    allow(Rails.cache).to receive(:fetch).and_yield
    client = instance_double(Whatsapp::FacebookApiClient, fetch_product_catalogs: { 'data' => [{ 'id' => 'catalog-id' }] })
    allow(Whatsapp::FacebookApiClient).to receive(:new).with('token').and_return(client)
  end

  context 'with a single-product template' do
    let(:template) do
      {
        'components' => [
          { 'type' => 'HEADER', 'format' => 'PRODUCT' },
          { 'type' => 'BUTTONS', 'buttons' => [{ 'type' => 'SPM', 'text' => 'View' }] }
        ]
      }
    end

    it 'builds the product header using the connected catalog' do
      result = described_class.new(
        channel: channel, template: template,
        processed_params: { 'product' => { 'product_retailer_id' => 'sku-1' } }
      ).call

      expect(result).to eq([
                             {
                               type: 'header',
                               parameters: [
                                 { type: 'product', product: { catalog_id: 'catalog-id', product_retailer_id: 'sku-1' } }
                               ]
                             }
                           ])
    end
  end

  context 'with a multi-product template' do
    let(:template) do
      { 'components' => [{ 'type' => 'BUTTONS', 'buttons' => [{ 'type' => 'MPM', 'text' => 'View items' }] }] }
    end

    it 'builds thumbnail and section actions' do
      result = described_class.new(
        channel: channel, template: template,
        processed_params: {
          'catalog' => {
            'thumbnail_product_retailer_id' => 'sku-1',
            'sections' => [{ 'title' => 'Featured', 'product_retailer_ids' => %w[sku-1 sku-2] }]
          }
        }
      ).call

      expect(result.first).to include(type: 'button', sub_type: 'mpm', index: '0')
      products = result.first.dig(:parameters, 0, :action, :sections, 0, :product_items)
      expect(products).to eq([{ product_retailer_id: 'sku-1' }, { product_retailer_id: 'sku-2' }])
    end
  end
end

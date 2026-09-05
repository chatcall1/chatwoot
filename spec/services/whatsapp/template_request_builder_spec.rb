require 'rails_helper'

RSpec.describe Whatsapp::TemplateRequestBuilder do
  describe '#build' do
    context 'with a named standard template' do
      let(:payload) do
        {
          'name' => 'order_update', 'language' => 'en_US', 'category' => 'UTILITY',
          'parameter_format' => 'NAMED', 'template_format' => 'standard', 'header_type' => 'text',
          'header_text' => 'Hello {{customer_name}}', 'header_example' => 'Jane',
          'body' => 'Order {{order_number}} is ready', 'body_examples' => { 'order_number' => 'A-100' },
          'footer' => '', 'buttons' => []
        }
      end

      it 'uses Meta named parameter examples' do
        request = described_class.new(payload).build([])

        expect(request).to include(parameter_format: 'named')
        expect(request[:components]).to include(
          hash_including(type: 'HEADER', example: { header_text_named_params: [{ param_name: 'customer_name', example: 'Jane' }] }),
          hash_including(type: 'BODY', example: { body_text_named_params: [{ param_name: 'order_number', example: 'A-100' }] })
        )
      end

      it 'does not add Marketing Messages settings to template creation' do
        request = described_class.new(payload.merge('category' => 'MARKETING', 'marketing_messages_enabled' => true)).build([])

        expect(request).not_to include(:message_send_ttl_seconds, :degrees_of_freedom_spec)
      end
    end

    context 'with a catalog template' do
      let(:payload) do
        {
          'name' => 'shop_catalog', 'language' => 'ar', 'category' => 'MARKETING',
          'parameter_format' => 'POSITIONAL', 'catalog_format' => 'catalog_template',
          'body' => 'تصفح منتجاتنا', 'body_examples' => [], 'footer' => ''
        }
      end

      it 'uses the language-specific system button text' do
        request = described_class.new(payload).build([])

        expect(request[:components].last).to eq(
          type: 'BUTTONS', buttons: [{ type: 'CATALOG', text: 'عرض الكتالوج' }]
        )
      end
    end

    context 'with a product carousel template' do
      let(:payload) do
        {
          'name' => 'products', 'language' => 'en_US', 'category' => 'MARKETING',
          'parameter_format' => 'POSITIONAL', 'catalog_format' => 'product_carousel',
          'body' => 'Our products', 'body_examples' => [], 'product_carousel_button_type' => 'SPM'
        }
      end

      it 'creates the two cards required for template review' do
        carousel = described_class.new(payload).build([])[:components].last

        expect(carousel).to include(type: 'CAROUSEL')
        expect(carousel[:cards].length).to eq(2)
        expect(carousel[:cards]).to all(
          include(components: include(type: 'HEADER', format: 'PRODUCT'))
        )
      end
    end
  end
end

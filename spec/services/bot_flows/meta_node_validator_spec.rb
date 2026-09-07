require 'rails_helper'

RSpec.describe BotFlows::MetaNodeValidator do
  describe '#errors' do
    it 'validates supported node types without raising a private-method error' do
      node = {
        'type' => 'cta_url',
        'data' => {
          'body' => 'افتح الرابط',
          'buttonText' => 'فتح',
          'url' => 'https://example.com',
          'headerType' => 'none'
        }
      }

      expect(described_class.new(node).errors).to be_empty
    end

    it 'rejects unknown node types before dispatching validation' do
      expect do
        described_class.new('type' => 'unknown', 'data' => {}).errors
      end.to raise_error(ArgumentError, /Unsupported Meta node type/)
    end
  end
end

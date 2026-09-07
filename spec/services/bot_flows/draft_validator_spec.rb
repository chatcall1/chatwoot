require 'rails_helper'

RSpec.describe BotFlows::DraftValidator do
  describe '#errors' do
    it 'allows an incomplete draft with an unconnected trigger' do
      definition = {
        'nodes' => [{ 'id' => 'trigger-1', 'type' => 'trigger', 'data' => { 'mode' => 'exact_match' } }],
        'edges' => []
      }

      expect(described_class.new(definition).errors).to be_empty
    end

    it 'allows temporarily disconnected supported nodes' do
      definition = {
        'nodes' => [
          { 'id' => 'trigger-1', 'type' => 'trigger', 'data' => { 'mode' => 'exact_match' } },
          { 'id' => 'text-1', 'type' => 'text', 'data' => { 'content' => '' } }
        ],
        'edges' => []
      }

      expect(described_class.new(definition).errors).to be_empty
    end

    it 'still rejects edges that reference missing nodes' do
      definition = {
        'nodes' => [{ 'id' => 'trigger-1', 'type' => 'trigger', 'data' => { 'mode' => 'exact_match' } }],
        'edges' => [{ 'source' => 'trigger-1', 'target' => 'missing' }]
      }

      expect(described_class.new(definition).errors).to include('edges must connect two different existing nodes')
    end
  end
end

class BotFlows::TriggerIndexer
  def initialize(flow)
    @flow = flow
  end

  def call
    flow.bot_flow_triggers.delete_all
    return unless flow.published?

    trigger['mode'] == 'no_match' ? index_no_match : index_exact_matches
  end

  private

  attr_reader :flow

  def index_no_match
    flow.bot_flow_triggers.create!(account: flow.account, inbox: flow.inbox, trigger_kind: 'no_match')
  end

  def index_exact_matches
    return unless trigger['mode'] == 'exact_match'

    normalized_keywords.each do |value|
      flow.bot_flow_triggers.create!(account: flow.account, inbox: flow.inbox, trigger_kind: 'exact_match', normalized_value: value,
                                     value_hash: BotFlowTrigger.fingerprint(value))
    end
  end

  def trigger
    flow.published_definition.to_h.fetch('nodes', []).find { |node| node['type'] == 'trigger' }.to_h.fetch('data', {})
  end

  def normalized_keywords
    Array(trigger['keywords']).filter_map { |keyword| BotFlowTrigger.normalize(keyword).presence }.uniq
  end
end

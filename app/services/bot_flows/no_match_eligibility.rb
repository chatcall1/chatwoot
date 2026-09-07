class BotFlows::NoMatchEligibility
  def initialize(flow, contact_id)
    @flow = flow
    @contact_id = contact_id
  end

  def call
    cutoff = cutoff_for(frequency)
    return true unless cutoff

    flow.bot_flow_executions.where(contact_id: contact_id, trigger_kind: 'no_match', created_at: cutoff..).none?
  end

  private

  attr_reader :flow, :contact_id

  def frequency
    trigger = flow.published_definition.fetch('nodes', []).find { |node| node['type'] == 'trigger' }
    trigger.to_h.dig('data', 'noMatchFrequency') || 'always'
  end

  def cutoff_for(value)
    {
      'daily' => 1.day.ago,
      'weekly' => 1.week.ago,
      'monthly' => 1.month.ago
    }[value]
  end
end

class CreateBotFlowTriggers < ActiveRecord::Migration[7.1]
  def up
    create_table :bot_flow_triggers do |t|
      t.references :bot_flow, null: false, foreign_key: { on_delete: :cascade }
      t.references :account, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :inbox, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.string :trigger_kind, null: false
      t.text :normalized_value
      t.string :value_hash, limit: 64
      t.timestamps
    end
    add_index :bot_flow_triggers, [:account_id, :inbox_id, :value_hash], unique: true,
                                                                         where: "trigger_kind = 'exact_match'",
                                                                         name: 'idx_bot_flow_triggers_exact_lookup'
    add_index :bot_flow_triggers, [:account_id, :inbox_id], unique: true,
                                                            where: "trigger_kind = 'no_match'",
                                                            name: 'idx_bot_flow_triggers_no_match_lookup'
    backfill_published_triggers
  end

  def down
    drop_table :bot_flow_triggers
  end

  private

  def backfill_published_triggers
    migration_bot_flow.where(status: 1).find_each do |flow|
      trigger = flow.published_definition.to_h.fetch('nodes', []).find { |node| node['type'] == 'trigger' }.to_h
      mode = trigger.dig('data', 'mode')

      backfill_trigger(flow, mode, trigger)
    end
  end

  def backfill_trigger(flow, mode, trigger)
    return create_no_match_trigger(flow) if mode == 'no_match'
    return unless mode == 'exact_match'

    normalized_keywords(trigger).each { |value| create_exact_trigger(flow, value) }
  end

  def create_no_match_trigger(flow)
    migration_trigger.create!(bot_flow_id: flow.id, account_id: flow.account_id, inbox_id: flow.inbox_id,
                              trigger_kind: 'no_match')
  end

  def create_exact_trigger(flow, value)
    migration_trigger.create!(bot_flow_id: flow.id, account_id: flow.account_id, inbox_id: flow.inbox_id,
                              trigger_kind: 'exact_match', normalized_value: value, value_hash: Digest::SHA256.hexdigest(value))
  end

  def normalized_keywords(trigger)
    Array(trigger.dig('data', 'keywords')).filter_map { |keyword| normalize(keyword).presence }.uniq
  end

  def normalize(value)
    value.to_s.unicode_normalize(:nfkc).strip.downcase
  end

  def migration_bot_flow
    @migration_bot_flow ||= Class.new(ActiveRecord::Base) { self.table_name = 'bot_flows' }
  end

  def migration_trigger
    @migration_trigger ||= Class.new(ActiveRecord::Base) { self.table_name = 'bot_flow_triggers' }
  end
end

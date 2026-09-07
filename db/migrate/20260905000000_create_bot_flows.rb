class CreateBotFlows < ActiveRecord::Migration[7.1]
  def change
    create_table :bot_flows do |t|
      t.references :account, null: false, foreign_key: true, index: false
      t.references :inbox, null: false, foreign_key: true
      t.string :identifier, null: false
      t.string :name, null: false
      t.string :trigger_kind, null: false
      t.integer :status, null: false, default: 0
      t.jsonb :draft_definition, null: false, default: {}
      t.jsonb :published_definition
      t.datetime :published_at
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end

    add_index :bot_flows, [:account_id, :identifier], unique: true
    add_index :bot_flows, [:account_id, :updated_at]
    add_index :bot_flows, [:account_id, :inbox_id],
              unique: true,
              where: "trigger_kind = 'no_match'",
              name: 'index_bot_flows_unique_no_match_per_inbox'
  end
end

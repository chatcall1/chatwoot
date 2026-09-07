class CreateBotFlowExecutions < ActiveRecord::Migration[7.1]
  def change
    create_executions
    create_deliveries
  end

  private

  def create_executions
    create_table :bot_flow_executions do |t|
      t.references :bot_flow, null: false, foreign_key: { on_delete: :cascade }
      t.references :account, null: false, foreign_key: { on_delete: :cascade }
      t.references :inbox, null: false, foreign_key: { on_delete: :cascade }
      t.references :conversation, null: false, foreign_key: { on_delete: :cascade }, type: :integer
      t.references :contact, null: false, foreign_key: { on_delete: :cascade }
      t.references :trigger_message, null: false, foreign_key: { to_table: :messages, on_delete: :cascade },
                                     type: :integer, index: { unique: true }
      t.string :trigger_kind, null: false
      t.string :current_node_id
      t.integer :status, null: false, default: 0
      t.jsonb :context, null: false, default: {}
      t.datetime :completed_at
      t.timestamps
    end

    add_index :bot_flow_executions, [:bot_flow_id, :contact_id, :created_at],
              name: 'index_bot_flow_executions_on_flow_contact_created_at'
  end

  def create_deliveries
    create_table :bot_flow_deliveries do |t|
      t.references :bot_flow_execution, null: false, foreign_key: { on_delete: :cascade }
      t.references :message, foreign_key: { on_delete: :nullify }, type: :integer
      t.string :node_id, null: false
      t.integer :status, null: false, default: 0
      t.integer :attempt_count, null: false, default: 0
      t.datetime :last_attempt_at
      t.datetime :retry_scheduled_at
      t.text :last_error
      t.timestamps
    end

    add_index :bot_flow_deliveries, [:bot_flow_execution_id, :node_id],
              unique: true,
              name: 'index_bot_flow_deliveries_on_execution_and_node'
  end
end

class CreateWhatsappTemplateMedia < ActiveRecord::Migration[7.0]
  def change
    create_table :whatsapp_template_media do |t|
      t.references :channel, null: false, foreign_key: { to_table: :channel_whatsapp }
      t.string :template_name, null: false
      t.integer :card_index, null: false
      t.string :media_type, null: false
      t.timestamps
    end

    add_index :whatsapp_template_media, [:channel_id, :template_name, :card_index],
              unique: true, name: 'index_whatsapp_template_media_on_template_card'
  end
end

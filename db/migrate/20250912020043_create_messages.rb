class CreateMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :messages do |t|
      t.references :chat, null: false, foreign_key: true
      t.string :role, null: false
      t.text :content
      t.references :model, foreign_key: true
      t.integer :input_tokens
      t.integer :output_tokens
      t.references :tool_call, foreign_key: true
      t.timestamps
    end

    add_index :messages, :role
  end
end

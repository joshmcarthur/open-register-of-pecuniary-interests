class CreateInterests < ActiveRecord::Migration[8.0]
  def change
    create_table :interests do |t|
      t.text :description, null: false
      t.belongs_to :interest_category, null: false, foreign_key: true
      t.belongs_to :political_entity_jurisdiction, null: false, foreign_key: true
      t.belongs_to :source, null: false, foreign_key: true
      t.text :source_page_numbers, default: '[]'
      t.json :metadata, default: {}

      t.timestamps
    end
  end
end

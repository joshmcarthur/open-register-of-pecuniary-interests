class CreatePoliticalEntities < ActiveRecord::Migration[8.0]
  def change
    create_table :political_entities do |t|
      t.string :name, null: false
      t.index :name, unique: true
      t.text :description

      t.timestamps
    end
  end
end

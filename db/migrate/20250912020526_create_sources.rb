class CreateSources < ActiveRecord::Migration[8.0]
  def change
    create_table :sources do |t|
      t.string :name, null: false
      t.integer :year, null: false
      t.json :metadata
      t.text :description
      t.index :name, unique: true

      t.timestamps
    end
  end
end

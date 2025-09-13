class CreateInterestCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :interest_categories do |t|
      t.string :key, null: false
      t.string :label, null: false
      t.index :key, unique: true

      t.timestamps
    end
  end
end

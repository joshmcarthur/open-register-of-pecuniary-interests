class CreateJurisdictions < ActiveRecord::Migration[8.0]
  def change
    create_table :jurisdictions do |t|
      t.string :name, null: false
      t.string :jurisdiction_type, null: false
      t.text :description

      t.timestamps
    end
  end
end

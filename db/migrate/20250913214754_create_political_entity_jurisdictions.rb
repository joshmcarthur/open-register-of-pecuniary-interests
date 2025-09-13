class CreatePoliticalEntityJurisdictions < ActiveRecord::Migration[8.0]
  def change
    create_table :political_entity_jurisdictions do |t|
      t.belongs_to :political_entity, null: false, foreign_key: true
      t.belongs_to :jurisdiction, null: false, foreign_key: true
      t.string :role, null: false
      t.string :electorate
      t.string :affiliation
      t.date :start_date
      t.date :end_date

      t.timestamps
    end
  end
end

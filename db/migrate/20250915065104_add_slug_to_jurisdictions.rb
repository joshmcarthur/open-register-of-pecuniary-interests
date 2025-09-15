class AddSlugToJurisdictions < ActiveRecord::Migration[8.0]
  class Jurisdiction < ApplicationRecord
    self.table_name = "jurisdictions"
  end

  def up
    add_column :jurisdictions, :slug, :string, null: true
    Jurisdiction.find_each do |jurisdiction|
      jurisdiction.update(slug: jurisdiction.name.parameterize)
    end
    change_column :jurisdictions, :slug, :string, null: false
    add_index :jurisdictions, :slug, unique: true
  end

  def down
    remove_column :jurisdictions, :slug
  end
end

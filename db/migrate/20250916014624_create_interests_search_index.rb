class CreateInterestsSearchIndex < ActiveRecord::Migration[8.0]
  def change
    create_virtual_table :interests_search_index, :fts5, [
      'interest_id UNINDEXED',
      'description',
      'political_entity_name',
      'jurisdiction_name',
      'interest_category_label',
      "tokenize='trigram remove_diacritics 1'"
    ]
  end
end

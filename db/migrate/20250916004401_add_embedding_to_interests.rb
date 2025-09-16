class AddEmbeddingToInterests < ActiveRecord::Migration[8.0]
  def change
    add_column :interests, :embedding, :binary
    add_index :interests, :embedding, using: :neighbor
  end
end

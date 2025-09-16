class Interest < ApplicationRecord
  belongs_to :political_entity_jurisdiction
  has_one :political_entity, through: :political_entity_jurisdiction
  has_one :jurisdiction, through: :political_entity_jurisdiction
  has_neighbors :embedding

  belongs_to :source
  belongs_to :interest_category
  serialize :source_page_numbers, coder: JSON

  validates :description, presence: true
  after_create_commit :create_in_search_index
  after_update_commit :update_in_search_index
  after_destroy_commit :remove_from_search_index

  scope :search, ->(query) do
    joins("join interests_search_index idx on interests.id = idx.interest_id")
    .select("interests.*, idx.rank")
    .where("interests_search_index match ?", query)
  end

  def self.rebuild_search_index
    connection.execute "INSERT INTO interests_search_index(interests_search_index) VALUES('rebuild')"
  end

  private


  def create_in_search_index
    generate_embedding
    execute_sql_with_binds "
      insert into interests_search_index (interest_id, description, political_entity_name, jurisdiction_name, interest_category_label) values (?, ?, ?, ?, ?)
    ", id, description, political_entity.name, jurisdiction.name, interest_category.label
  end

  def update_in_search_index
    return unless saved_change_to_description?

    generate_embedding

    transaction do
      remove_from_search_index
      create_in_search_index
    end
  end

  def remove_from_search_index
    execute_sql_with_binds "
      delete from interests_search_index where interest_id = ?
    ", id
  end

  def generate_embedding
    embedding = EmbeddingService.generate_embedding([
      description,
      political_entity.name,
      jurisdiction.name,
      interest_category.label
    ].join("\n\n"))

    update_column(:embedding, embedding)
  end

  def execute_sql_with_binds(*statement)
    self.class.connection.execute self.class.sanitize_sql(statement)
  end
end

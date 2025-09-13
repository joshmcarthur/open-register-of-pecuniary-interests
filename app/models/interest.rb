class Interest < ApplicationRecord
  belongs_to :political_entity_jurisdiction
  has_one :political_entity, through: :political_entity_jurisdiction
  has_one :jurisdiction, through: :political_entity_jurisdiction
  belongs_to :source
  belongs_to :interest_category
  serialize :source_page_numbers, coder: JSON

  validates :description, presence: true
end

class Jurisdiction < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :jurisdiction_type, presence: true

  enum :jurisdiction_type, {
    parliament: "parliament",
    regional_council: "regional_council",
    local_council: "local_council"
  }

  has_many :political_entity_jurisdictions
  has_many :political_entities, through: :political_entity_jurisdictions
  has_many :interests, through: :political_entity_jurisdictions
end

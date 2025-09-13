class PoliticalEntity < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  has_many :political_entity_jurisdictions
  has_many :jurisdictions, through: :political_entity_jurisdictions
  has_many :interests, through: :political_entity_jurisdictions
end

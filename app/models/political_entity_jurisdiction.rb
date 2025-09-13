class PoliticalEntityJurisdiction < ApplicationRecord
  belongs_to :political_entity
  belongs_to :jurisdiction
  has_many :interests

  validates :role, presence: true
end

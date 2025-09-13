class Source < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :year, presence: true

  has_one_attached :file
  has_many :interests
  has_many :interest_categories, through: :interests
  has_many :political_entities, through: :interests
  has_many :jurisdictions, through: :interests
end

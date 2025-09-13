class InterestCategory < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  validates :label, presence: true

  has_many :interests
end

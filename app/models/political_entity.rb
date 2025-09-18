class PoliticalEntity < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  has_many :political_entity_jurisdictions
  has_many :jurisdictions, through: :political_entity_jurisdictions
  has_many :interests, through: :political_entity_jurisdictions
  has_one_attached :profile_image do |attachable|
    attachable.variant :thumbnail, resize_to_limit: [ 256, 256 ], format: :webp
    attachable.variant :small, resize_to_limit: [ 128, 128 ], format: :webp
  end

  def to_param
    [ id, name.parameterize ].join("-")
  end
end

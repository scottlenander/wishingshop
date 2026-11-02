class AnnouncementProduct < ApplicationRecord
  belongs_to :announcement
  belongs_to :product

  validates :product_id, uniqueness: { scope: :announcement_id }
end

class Product < ApplicationRecord
  include Notifications

  has_one_attached :featured_image do |attachable|
    # Smaller copy for the product cards on the index page.
    attachable.variant :thumb, resize_to_limit: [ 600, 600 ]
  end
  has_rich_text :description

  validates :name, presence: true
  validates :inventory_count, numericality: { greater_than_or_equal_to: 0 }
end

class OrderItem < ApplicationRecord
  belongs_to :order
  # Optional so the order keeps its history if the product is deleted.
  belongs_to :product, optional: true

  validates :product_name, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def line_total_cents = unit_price_cents * quantity
end

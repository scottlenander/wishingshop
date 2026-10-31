class Product < ApplicationRecord
  include Notifications

  class NotEnoughStock < StandardError; end

  has_one_attached :featured_image do |attachable|
    # Smaller copy for the product cards on the index page.
    attachable.variant :thumb, resize_to_limit: [ 600, 600 ]
  end
  has_rich_text :description
  has_many :orders, dependent: :nullify

  validates :name, presence: true
  validates :inventory_count, numericality: { greater_than_or_equal_to: 0 }

  # Buys `quantity` for `user`: lowers stock and records an order.
  # The stock check and decrement are one UPDATE, so two buyers at once can't
  # oversell. Raises NotEnoughStock (nothing changes) if there isn't enough.
  def purchase!(user, quantity)
    quantity = Integer(quantity, exception: false)
    raise ArgumentError, "Quantity must be a whole number of 1 or more" unless quantity&.positive?

    transaction do
      updated = Product.where(id: id).where(inventory_count: quantity..)
                       .update_all([ "inventory_count = inventory_count - ?, updated_at = ?", quantity, Time.current ])
      raise NotEnoughStock, "Only #{reload.inventory_count} #{name} left in stock" if updated.zero?

      reload
      orders.create!(user: user, product_name: name, quantity: quantity)
    end
  end
end

class Product < ApplicationRecord
  include Notifications

  class NotEnoughStock < StandardError; end

  SKU_FORMAT = /\A[A-Z0-9-]+\z/

  has_one_attached :featured_image do |attachable|
    # Smaller copy for the product cards on the index page.
    attachable.variant :thumb, resize_to_limit: [ 600, 600 ]
  end
  has_rich_text :description
  has_many :orders, dependent: :nullify

  normalizes :sku, with: ->(sku) { sku.strip.upcase }

  # Products created without a SKU get one from the name ("T-Shirt" -> "T-SHIRT").
  before_validation :default_sku, on: :create

  validates :name, presence: true
  validates :sku, presence: true, uniqueness: true,
                  format: { with: SKU_FORMAT, message: "can only contain letters, numbers and dashes" }
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

  private
    def default_sku
      self.sku = name.to_s.parameterize.upcase if sku.blank?
    end
end

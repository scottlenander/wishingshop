# A signed-in user's saved cart. Visitors use VisitorCart (session cookie),
# which is merged in here when they log in.
class Cart < ApplicationRecord
  include CartContents

  belongs_to :user
  has_many :cart_items, -> { order(:created_at) }, dependent: :destroy, inverse_of: :cart
  has_many :products, through: :cart_items

  def items
    cart_items.includes(product: { featured_image_attachment: :blob })
  end

  # Adds to the cart, capped at what's in stock. Returns [item, message] where
  # message explains a cap, or nil.
  def add(product, quantity)
    item = cart_items.find_or_initialize_by(product: product)
    item.quantity, message = quantity_after_add(product, item.new_record? ? 0 : item.quantity, quantity)
    item.save!
    touch
    [ item, message ]
  end

  def find_item(id) = cart_items.find(id)
  def set_quantity(item, quantity) = item.update!(quantity: quantity)
  def remove(item) = item.destroy

  # Moves a visitor's cart in (on login), capped at stock, then empties it.
  def merge!(visitor_cart)
    return if visitor_cart.nil? || visitor_cart.empty?

    transaction do
      visitor_cart.items.each do |item|
        add(item.product, item.quantity) if item.product.for_sale? && item.product.inventory_count.positive?
      end
    end
    visitor_cart.clear
    cart_items.reset
  end
end

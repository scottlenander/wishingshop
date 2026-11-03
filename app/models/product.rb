class Product < ApplicationRecord
  include Notifications

  class NotEnoughStock < StandardError; end

  SKU_FORMAT = /\A[A-Z0-9-]+\z/

  has_one_attached :featured_image do |attachable|
    # Smaller copy for the product cards on the index page.
    attachable.variant :thumb, resize_to_limit: [ 600, 600 ]
  end
  has_rich_text :description
  has_many :cart_items, dependent: :destroy
  has_many :order_items, dependent: :nullify
  has_many :reviews, dependent: :destroy
  has_many :featured_products, dependent: :destroy
  has_many :announcement_products, dependent: :destroy

  normalizes :sku, with: ->(sku) { sku.strip.upcase }

  # Products created without a SKU get one from the name ("T-Shirt" -> "T-SHIRT").
  before_validation :default_sku, on: :create

  validates :name, presence: true
  validates :sku, presence: true, uniqueness: true,
                  format: { with: SKU_FORMAT, message: "can only contain letters, numbers and dashes" }
  validates :inventory_count, numericality: { greater_than_or_equal_to: 0 }
  validates :price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0,
                                          message: "must be a dollar amount like 19.99" }

  # Lowers stock by `quantity`. The check and the decrease are one UPDATE, so
  # two buyers at once can't oversell. Raises NotEnoughStock if there isn't
  # enough (nothing changes).
  def self.take_stock!(product_id, quantity)
    updated = where(id: product_id).where(inventory_count: quantity..)
                                   .update_all([ "inventory_count = inventory_count - ?, updated_at = ?", quantity, Time.current ])
    return if updated.positive?

    product = find(product_id)
    raise NotEnoughStock, "Only #{product.inventory_count} #{product.name} left in stock"
  end

  # Price in dollars for forms and CSV ("19.99"); stored as whole cents.
  def price
    price_cents && BigDecimal(price_cents) / 100
  end

  def price=(value)
    text = value.to_s.strip.delete_prefix("$").delete(",")
    self.price_cents = text.match?(/\A\d+(\.\d{1,2})?\z/) ? (BigDecimal(text) * 100).to_i : text.presence && -1
  end

  def for_sale? = price_cents.to_i.positive?

  # Average (to 0.1), count, and how many reviews gave each star level.
  RatingSummary = Data.define(:average, :count, :breakdown) do
    def any? = count.positive?
  end

  # Average rating (to 0.1) and review count for many products in one query,
  # e.g. for the product cards: { product_id => [4.3, 12] }. Unrated products
  # aren't in the hash.
  def self.ratings_for(product_ids)
    Review.where(product_id: product_ids).group(:product_id)
          .pluck(:product_id, Arel.sql("AVG(rating)"), Arel.sql("COUNT(*)"))
          .to_h { |id, average, count| [ id, [ average.to_f.round(1), count ] ] }
  end

  def rating_summary
    counts = reviews.group(:rating).count
    total = counts.values.sum
    average = total.zero? ? nil : (counts.sum { |stars, n| stars * n }.to_f / total).round(1)
    RatingSummary.new(average: average, count: total, breakdown: 5.downto(1).to_h { |stars| [ stars, counts.fetch(stars, 0) ] })
  end

  # "Price must be a dollar amount", not "Price cents ...".
  def self.human_attribute_name(attribute, options = {})
    attribute.to_s == "price_cents" ? "Price" : super
  end

  private
    def default_sku
      self.sku = name.to_s.parameterize.upcase if sku.blank?
    end
end

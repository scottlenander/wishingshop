# A customer's review of a product: 1-5 stars and some text. Only people who
# have ordered the product can review it, once each.
class Review < ApplicationRecord
  PAGE_SIZE = 10
  FIRST_PAGE = 3
  BODY_LENGTH = 10..2000

  belongs_to :user
  belongs_to :product

  normalizes :body, with: ->(body) { body.strip.gsub(/[ \t]+/, " ").gsub(/\n{3,}/, "\n\n") }

  validates :rating, numericality: { only_integer: true, in: 1..5, message: "must be 1 to 5 stars" }
  validates :body, length: { in: BODY_LENGTH, too_short: "is too short (at least %{count} characters)" }
  validate :one_per_product, :purchased_by_author, on: :create

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  def self.human_attribute_name(attribute, options = {})
    attribute.to_s == "body" ? "Review" : super
  end

  # "Alice C." rather than the full name.
  def author_name = "#{user.first_name} #{user.last_name.first}."

  def edited? = updated_at > created_at + 1.minute

  private
    def one_per_product
      return unless Review.exists?(user_id: user_id, product_id: product_id)

      errors.add(:base, "You've already reviewed this product")
    end

    def purchased_by_author
      return if user.nil? || product.nil? || user.purchased?(product)

      errors.add(:base, "Only customers who bought this can review it")
    end
end

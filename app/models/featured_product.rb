# An admin's pick for the homepage featured product, for a set time window.
# When no pick is active, the homepage shows a random product that changes daily.
class FeaturedProduct < ApplicationRecord
  belongs_to :product
  belongs_to :user, optional: true

  validates :starts_at, :ends_at, presence: true
  validate :ends_after_start
  validate :no_overlapping_pick

  scope :active_at, ->(time) { where(starts_at: ..time).where("ends_at > ?", time) }
  scope :upcoming, ->(time = Time.current) { where("starts_at > ?", time).order(:starts_at) }
  scope :past, ->(time = Time.current) { where(ends_at: ..time).order(ends_at: :desc) }
  scope :overlapping, ->(from, to) { where("starts_at < ? AND ends_at > ?", to, from) }

  # Returns [product, :admin] for an active pick, [product, :random] for the
  # daily random pick, or nil when there are no products to show.
  def self.product_for(time = Time.current)
    if (pick = active_at(time).includes(:product).order(:starts_at).first)
      return [ pick.product, :admin ]
    end

    product = random_for(time.to_date)
    [ product, :random ] if product
  end

  # Same product for everyone all day: the day number seeds the choice.
  # Prefers in-stock products with an image, then any in-stock product.
  def self.random_for(date)
    in_stock = Product.where("inventory_count > 0").order(:id)
    candidates = in_stock.joins(:featured_image_attachment).to_a.presence || in_stock.to_a
    candidates.sample(random: Random.new(date.jd)) if candidates.any?
  end

  def active?(time = Time.current)
    starts_at <= time && ends_at > time
  end

  private
    def ends_after_start
      return if starts_at.blank? || ends_at.blank?

      errors.add(:ends_at, "must be after the start") if ends_at <= starts_at
    end

    def no_overlapping_pick
      return if starts_at.blank? || ends_at.blank?

      clash = FeaturedProduct.overlapping(starts_at, ends_at).where.not(id: id).includes(:product).first
      return unless clash

      errors.add(:base, "Overlaps with #{clash.product.name}, featured " \
                        "#{clash.starts_at.to_fs(:short)} – #{clash.ends_at.to_fs(:short)}")
    end
end

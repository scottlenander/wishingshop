# A homepage carousel slide: new products, sales or general news.
class Announcement < ApplicationRecord
  KIND_LABELS = { "general" => "News", "new_product" => "New", "sale" => "Sale" }.freeze

  enum :kind, { general: "general", new_product: "new_product", sale: "sale" }, default: :general, validate: true

  has_many :announcement_products, dependent: :destroy
  has_many :products, through: :announcement_products
  has_one_attached :image

  attribute :starts_at, :datetime, default: -> { Time.current }

  validates :title, presence: true, length: { maximum: 80 }
  validates :body, length: { maximum: 280 }
  validates :starts_at, presence: true
  validates :position, numericality: { only_integer: true }
  validate :ends_after_start

  scope :live, ->(time = Time.current) {
    where(starts_at: ..time).where("ends_at IS NULL OR ends_at > ?", time).order(:position, starts_at: :desc)
  }

  def kind_label = KIND_LABELS.fetch(kind)

  def status(time = Time.current)
    if starts_at > time then "Scheduled"
    elsif ends_at && ends_at <= time then "Ended"
    else "Live"
    end
  end

  private
    def ends_after_start
      return if starts_at.blank? || ends_at.blank?

      errors.add(:ends_at, "must be after the start") if ends_at <= starts_at
    end
end

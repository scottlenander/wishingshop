# A placed order. Items, prices, address and shipping are copied in at
# checkout, so history stays the same if products change later.
class Order < ApplicationRecord
  belongs_to :user
  has_many :order_items, dependent: :destroy

  before_validation :assign_number, on: :create
  before_validation -> { self.placed_at ||= Time.current }, on: :create

  validates :number, presence: true, uniqueness: true
  validates :order_items, presence: true

  def to_param = number

  def item_count = order_items.sum(&:quantity)
  def shipping_option = ShippingMethod.find(shipping_method)

  # Orders from before checkout existed have no prices, address or payment.
  def legacy? = shipping_method.nil?

  def payment_summary = card_brand && "#{card_brand} ending #{card_last4}"

  def address_lines = lines_for(:ship)
  def billing_lines = bill_line1 ? lines_for(:bill) : []
  def ships_to_billing? = billing_lines == address_lines

  private
    def lines_for(prefix)
      name, line1, line2, city, state, zip = %w[ name line1 line2 city state postal_code ].map { |f| self[:"#{prefix}_#{f}"] }
      [ name, line1, line2.presence, "#{city}, #{state} #{zip}" ].compact
    end

    def assign_number
      self.number ||= loop do
        candidate = "WS-#{SecureRandom.alphanumeric(6).upcase}"
        break candidate unless Order.exists?(number: candidate)
      end
    end
end

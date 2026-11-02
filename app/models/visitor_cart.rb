# A visitor's cart, kept in the session cookie (encrypted and signed) as
# { "product_id" => quantity }. Nothing is saved in the database; when the
# visitor logs in it's merged into their saved Cart (see Cart#merge!).
#
# Has the same interface as Cart, so the cart page and nav work for both.
class VisitorCart
  include CartContents

  SESSION_KEY = :cart
  # Keeps the cookie well under the 4 KB limit.
  MAX_LINES = 50

  Item = Data.define(:product, :quantity) do
    def id = product.id
    def to_param = product.id.to_s
    def line_total_cents = product.price_cents * quantity
  end

  def initialize(session)
    @session = session
  end

  def items
    @items ||= begin
      lines = data
      products = Product.with_attached_featured_image.where(id: lines.keys).index_by { |p| p.id.to_s }
      # Products deleted since they were added are skipped.
      lines.filter_map { |id, quantity| products[id] && Item.new(product: products[id], quantity: quantity) }
    end
  end

  # Without loading products, for the nav badge.
  def item_count = data.values.sum

  # Returns [item, message] like Cart#add.
  def add(product, quantity)
    key = product.id.to_s
    lines = data
    raise ArgumentError, "Your cart is full. Log in to add more." if !lines.key?(key) && lines.size >= MAX_LINES

    stored, message = quantity_after_add(product, lines.fetch(key, 0), quantity)
    write(lines.merge(key => stored))
    [ Item.new(product: product, quantity: stored), message ]
  end

  def find_item(id)
    items.find { |item| item.id.to_s == id.to_s } or raise ActiveRecord::RecordNotFound, "No such item in your cart"
  end

  def set_quantity(item, quantity)
    write(data.merge(item.id.to_s => quantity))
  end

  def remove(item)
    write(data.except(item.id.to_s))
  end

  def clear
    @session.delete(SESSION_KEY)
    @items = nil
  end

  private
    # Only positive whole quantities survive, whatever is in the cookie.
    def data
      raw = @session[SESSION_KEY]
      return {} unless raw.is_a?(Hash)

      raw.each_with_object({}) do |(id, quantity), lines|
        lines[id.to_s] = quantity.to_i if id.to_s.match?(/\A\d+\z/) && quantity.to_i.positive?
      end
    end

    def write(lines)
      @items = nil
      lines.empty? ? @session.delete(SESSION_KEY) : @session[SESSION_KEY] = lines
    end
end

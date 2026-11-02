# Shipping options at checkout. A plain list, not a database table.
class ShippingMethod
  FREE_STANDARD_THRESHOLD_CENTS = 50_00

  Option = Data.define(:id, :label, :estimate, :price_cents) do
    # Standard is free on orders of $50 or more.
    def cost_cents(subtotal_cents)
      return 0 if id == "standard" && subtotal_cents >= FREE_STANDARD_THRESHOLD_CENTS

      price_cents
    end
  end

  ALL = [
    Option.new(id: "standard", label: "Standard", estimate: "3–5 business days", price_cents: 4_99),
    Option.new(id: "two_day", label: "Two-day", estimate: "2 business days", price_cents: 9_99),
    Option.new(id: "same_day", label: "Same-day", estimate: "Today, order by 2pm", price_cents: 19_99)
  ].freeze

  def self.all = ALL
  def self.ids = ALL.map(&:id)
  def self.find(id) = ALL.find { |option| option.id == id.to_s }
end

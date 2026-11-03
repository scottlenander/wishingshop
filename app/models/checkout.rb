# The checkout form: billing address, shipping address, shipping method and
# card. `place!` turns the cart into a paid order in one transaction.
#
# Shipping goes to the billing address unless `same_as_billing` is off. Then
# it's either a saved shipping address (`shipping_choice` = its id) or a new
# one (`shipping_choice` = "new"), which can be saved with a nickname.
class Checkout
  include ActiveModel::Model
  include ActiveModel::Attributes

  NEW_ADDRESS = "new"
  ADDRESS_FIELDS = Address::FIELDS

  # Readable names for error messages ("Billing ZIP code must be...").
  LABELS = {
    bill_name: "Billing full name", bill_line1: "Billing address", bill_line2: "Billing apartment, suite, etc.",
    bill_city: "Billing city", bill_state: "Billing state", bill_postal_code: "Billing ZIP code",
    ship_name: "Shipping full name", ship_line1: "Shipping address", ship_line2: "Shipping apartment, suite, etc.",
    ship_city: "Shipping city", ship_state: "Shipping state", ship_postal_code: "Shipping ZIP code",
    shipping_nickname: "Shipping address nickname", shipping_choice: "Shipping address",
    shipping_method: "Shipping method", card_name: "Name on card", card_number: "Card number",
    card_expiry: "Expiry (MM/YY)", card_cvc: "Security code (CVC)"
  }.freeze

  ADDRESS_FIELDS.each do |field|
    attribute :"bill_#{field}", :string
    attribute :"ship_#{field}", :string
  end
  attribute :save_billing, :boolean, default: false
  attribute :same_as_billing, :boolean, default: true
  attribute :shipping_choice, :string, default: NEW_ADDRESS
  attribute :save_shipping, :boolean, default: false
  attribute :shipping_nickname, :string
  attribute :shipping_method, :string, default: "standard"
  attribute :card_name, :string
  attribute :card_number, :string
  attribute :card_expiry, :string
  attribute :card_cvc, :string

  attr_accessor :user, :cart

  validates :shipping_method, inclusion: { in: ShippingMethod.ids, message: "must be chosen" }
  validate :billing_is_valid, :shipping_is_valid, :card_is_valid

  def self.human_attribute_name(attribute, options = {})
    LABELS.fetch(attribute.to_sym) { super }
  end

  # Form defaults for a user: their saved billing address (editable), and
  # their first saved shipping address if they have one.
  def self.for(user, cart)
    checkout = new(user: user, cart: cart, card_name: user.full_name, ship_name: user.full_name)
    if (billing = user.billing_address)
      billing.fields.each { |field, value| checkout.public_send(:"bill_#{field}=", value) }
    else
      checkout.bill_name = user.full_name
      checkout.save_billing = true
    end
    checkout.shipping_choice = user.shipping_addresses.first&.id&.to_s || NEW_ADDRESS
    checkout
  end

  def card
    @card ||= Payment::Card.new(name: card_name, number: card_number, expiry: card_expiry, cvc: card_cvc)
  end

  # Run before showing the form again after an error, so the full card number
  # and security code are never sent back to the browser. The name and expiry
  # are kept. With a real payment provider, card fields should be the
  # provider's hosted fields, so card details never reach this server at all.
  def clear_card_secrets
    self.card_number = nil
    self.card_cvc = nil
    @card = nil
  end

  def saved_shipping_addresses = user.shipping_addresses
  def new_shipping? = shipping_choice == NEW_ADDRESS

  def subtotal_cents = cart.subtotal_cents
  def shipping_cents = ShippingMethod.find(shipping_method)&.cost_cents(subtotal_cents).to_i
  def total_cents = subtotal_cents + shipping_cents

  # Returns the order, or nil with errors added (invalid details, stock
  # changed, card declined). A failure changes nothing: stock is only taken
  # inside the transaction, and the card is charged before anything is saved.
  def place!
    return unless valid?

    if (problem = cart.problems.first)
      errors.add(:base, problem)
      return
    end

    order = nil
    Order.transaction do
      items = cart.cart_items.includes(:product).to_a
      items.each { |item| Product.take_stock!(item.product_id, item.quantity) }

      order = user.orders.build(
        **prefixed(:bill, billing_fields), **prefixed(:ship, shipping_fields),
        shipping_method: shipping_method, subtotal_cents: subtotal_cents, shipping_cents: shipping_cents,
        total_cents: total_cents
      )
      items.each do |item|
        order.order_items.build(product: item.product, product_name: item.product.name, sku: item.product.sku,
                                unit_price_cents: item.product.price_cents, quantity: item.quantity)
      end

      payment = Payment::FakeGateway.charge(card, order.total_cents)
      order.assign_attributes(card_brand: payment[:brand], card_last4: payment[:last4])
      order.save!
      save_addresses!
      cart.cart_items.destroy_all
    end
    order
  rescue Product::NotEnoughStock, Payment::Declined => e
    errors.add(:base, e.message)
    nil
  end

  private
    # Tidied the same way saved addresses are (state upper-cased, spaces squished).
    def billing_fields = billing_address_candidate.fields

    # Where the order ships: the billing address, a saved address, or a new one.
    def shipping_fields
      if same_as_billing
        billing_fields
      elsif new_shipping?
        new_shipping_address_candidate.fields
      else
        saved_shipping_address.fields
      end
    end

    def saved_shipping_address
      @saved_shipping_address ||= saved_shipping_addresses.find_by(id: shipping_choice)
    end

    def fields_with_prefix(prefix)
      ADDRESS_FIELDS.to_h { |field| [ field, public_send(:"#{prefix}_#{field}") ] }
    end

    def prefixed(prefix, fields)
      fields.transform_keys { |field| :"#{prefix}_#{field}" }
    end

    # Uses Address's own rules, so checkout and My addresses agree.
    def billing_address_candidate
      Address.new(user: user, kind: :billing, **fields_with_prefix(:bill))
    end

    def new_shipping_address_candidate
      Address.new(user: user, kind: :shipping, nickname: shipping_nickname.presence || "Checkout", **fields_with_prefix(:ship))
    end

    def billing_is_valid
      copy_errors(billing_address_candidate, prefix: :bill, except: %i[ kind ])
    end

    def shipping_is_valid
      return if same_as_billing

      if new_shipping?
        candidate = new_shipping_address_candidate
        copy_errors(candidate, prefix: :ship, except: %i[ kind nickname ])
        if save_shipping
          if shipping_nickname.blank?
            errors.add(:shipping_nickname, "is needed to save the address")
          elsif candidate.errors.include?(:nickname)
            candidate.errors[:nickname].each { |message| errors.add(:shipping_nickname, message) }
          end
        end
      elsif saved_shipping_address.nil?
        errors.add(:shipping_choice, "must be chosen")
      end
    end

    def copy_errors(address, prefix:, except: [])
      address.validate
      address.errors.each do |error|
        next if except.include?(error.attribute)

        errors.add(error.attribute == :nickname ? :shipping_nickname : :"#{prefix}_#{error.attribute}", error.message)
      end
    end

    # Saves the billing address and/or a new shipping address if asked.
    def save_addresses!
      if save_billing
        billing = user.billing_address || user.addresses.build(kind: :billing)
        billing.update!(**billing_fields)
      end

      if !same_as_billing && new_shipping? && save_shipping
        user.addresses.create!(kind: :shipping, nickname: shipping_nickname, **fields_with_prefix(:ship))
      end
    end

    def card_is_valid
      return if card.valid?

      card.errors.each { |error| errors.add(:"card_#{error.attribute}", error.message) }
    end
end

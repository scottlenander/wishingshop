require "test_helper"

class CheckoutTest < ActiveSupport::TestCase
  VALID = {
    bill_name: "Olive One", bill_line1: "1 Main St", bill_city: "Springfield", bill_state: "il",
    bill_postal_code: "62701", shipping_method: "two_day",
    card_name: "Olive One", card_number: "4242 4242 4242 4242", card_expiry: "12/40", card_cvc: "123"
  }.freeze

  def checkout(**overrides)
    Checkout.new(VALID.merge(overrides).merge(user: users(:one), cart: carts(:one)))
  end

  test "places an order: snapshots items, totals, stock and empties the cart" do
    order = assert_difference("Order.count", 1) { checkout.place! }

    assert_equal [ [ "T-Shirt", "T-SHIRT", 1999, 2 ] ], order.order_items.map { |i| [ i.product_name, i.sku, i.unit_price_cents, i.quantity ] }
    assert_equal 3998, order.subtotal_cents
    assert_equal 999, order.shipping_cents
    assert_equal 4997, order.total_cents
    assert_equal "IL", order.ship_state
    assert_equal "Visa ending 4242", order.payment_summary
    assert_equal 13, products(:tshirt).reload.inventory_count
    assert carts(:one).reload.empty?
  end

  test "standard shipping is free from $50" do
    carts(:one).cart_items.first.update!(quantity: 3)
    order = checkout(shipping_method: "standard").place!
    assert_equal 0, order.shipping_cents
    assert_equal 5997, order.total_cents
  end

  test "never saves the full card number or code" do
    order = checkout.place!
    saved = order.attributes.values.map(&:to_s).join(" ")
    assert_no_match "4242424242424242", saved
    assert_no_match "4242 4242 4242 4242", saved
    assert_equal "4242", order.card_last4
  end

  test "a declined card changes nothing" do
    result = assert_no_difference("Order.count") { checkout(card_number: "4000 0000 0000 0002").place! }

    assert_nil result
    assert_equal 15, products(:tshirt).reload.inventory_count
    assert_equal 2, carts(:one).cart_items.first.quantity
  end

  test "not enough stock changes nothing" do
    products(:tshirt).update!(inventory_count: 1)
    c = checkout
    assert_nil c.place!
    assert_match "Only 1 T-Shirt left", c.errors.full_messages.first
    assert_equal 1, products(:tshirt).reload.inventory_count
  end

  test "validates the address, method and card with readable names" do
    c = checkout(bill_state: "Illinois", bill_postal_code: "6270", shipping_method: "teleport", card_cvc: "1")
    assert_not c.valid?
    messages = c.errors.full_messages
    assert_includes messages, "Billing state must be a 2-letter state code, like NY"
    assert_includes messages, "Billing ZIP code must be a ZIP code like 12345"
    assert_includes messages, "Shipping method must be chosen"
    assert_includes messages, "Security code (CVC) must be 3 or 4 digits"
  end

  test "ships to the billing address by default and copies both onto the order" do
    order = checkout.place!
    assert_equal [ "Olive One", "1 Main St", "Springfield, IL 62701" ], order.billing_lines
    assert_equal order.billing_lines, order.address_lines
    assert order.ships_to_billing?
  end

  test "a new shipping address is used, and saved with a nickname when asked" do
    order = assert_difference("Address.shipping.count", 1) do
      checkout(same_as_billing: false, shipping_choice: "new", ship_name: "Olive at Work", ship_line1: "9 Office Rd",
               ship_city: "Chicago", ship_state: "IL", ship_postal_code: "60601",
               save_shipping: true, shipping_nickname: "Work").place!
    end
    assert_equal "9 Office Rd", order.ship_line1
    assert_equal "1 Main St", order.bill_line1
    assert_equal "Work", users(:one).shipping_addresses.last.nickname
  end

  test "saving a new shipping address needs a unique nickname" do
    users(:one).addresses.create!(kind: :shipping, nickname: "Work", name: "O", line1: "1 A St", city: "X", state: "IL", postal_code: "60601")
    base = { same_as_billing: false, shipping_choice: "new", ship_name: "O", ship_line1: "2 B St", ship_city: "Y",
             ship_state: "IL", ship_postal_code: "60602", save_shipping: true }

    assert_includes checkout(**base, shipping_nickname: "").tap(&:valid?).errors.full_messages,
                    "Shipping address nickname is needed to save the address"
    assert_includes checkout(**base, shipping_nickname: "Work").tap(&:valid?).errors.full_messages,
                    "Shipping address nickname has already been taken"
  end

  test "a new shipping address is checked only when used" do
    c = checkout(same_as_billing: false, shipping_choice: "new")
    assert_not c.valid?
    assert_includes c.errors.full_messages, "Shipping ZIP code must be a ZIP code like 12345"
    assert checkout(ship_postal_code: "nonsense").valid?, "ignored when shipping to the billing address"
  end

  test "ships to a saved shipping address" do
    saved = users(:one).addresses.create!(kind: :shipping, nickname: "Cabin", name: "Olive One", line1: "5 Lake Rd",
                                          city: "Duluth", state: "MN", postal_code: "55802")
    order = checkout(same_as_billing: false, shipping_choice: saved.id.to_s).place!
    assert_equal "5 Lake Rd", order.ship_line1
    assert_equal "Duluth", order.ship_city
  end

  test "someone else's saved address can't be used" do
    other = users(:two).addresses.create!(kind: :shipping, nickname: "Home", name: "T", line1: "1 X St", city: "X",
                                          state: "OR", postal_code: "97201")
    c = checkout(same_as_billing: false, shipping_choice: other.id.to_s)
    assert_not c.valid?
    assert_includes c.errors.full_messages, "Shipping address must be chosen"
  end

  test "saves or updates the billing address only when asked" do
    assert_no_difference("Address.count") { checkout.place! }

    carts(:one).add(products(:tshirt), 1)
    checkout(save_billing: true).place!
    assert_equal "1 Main St", users(:one).reload.billing_address.line1

    carts(:one).add(products(:tshirt), 1)
    checkout(save_billing: true, bill_line1: "2 New St").place!
    assert_equal "2 New St", users(:one).reload.billing_address.line1
    assert_equal 1, users(:one).addresses.billing.count
  end

  test "a declined card saves no addresses" do
    assert_no_difference("Address.count") do
      checkout(card_number: "4000 0000 0000 0002", save_billing: true, same_as_billing: false, shipping_choice: "new",
               ship_name: "O", ship_line1: "2 B St", ship_city: "Y", ship_state: "IL", ship_postal_code: "60602",
               save_shipping: true, shipping_nickname: "Work").place!
    end
  end

  test "form defaults come from the saved billing address" do
    users(:one).addresses.create!(kind: :billing, name: "Olive One", line1: "7 Saved Ave", city: "Peoria", state: "IL", postal_code: "61602")
    defaults = Checkout.for(users(:one).reload, carts(:one))
    assert_equal "7 Saved Ave", defaults.bill_line1
    assert_not defaults.save_billing
    assert defaults.same_as_billing

    fresh = Checkout.for(users(:two), carts(:one))
    assert_equal "Tom Two", fresh.bill_name
    assert_equal "Tom Two", fresh.ship_name, "a new shipping address starts with the user's name"
    assert fresh.save_billing, "offers to save when nothing is saved yet"
  end
end

require "test_helper"

class CartTest < ActiveSupport::TestCase
  setup do
    @cart = carts(:one)
    @tshirt = products(:tshirt)
  end

  test "adds to an existing line" do
    assert_no_difference("CartItem.count") { @cart.add(@tshirt, 3) }
    assert_equal 5, cart_items(:one_tshirt).reload.quantity
  end

  test "adding is capped at stock, with a message" do
    item, message = @cart.add(@tshirt, 99)
    assert_equal 15, item.quantity
    assert_equal "Only 15 T-Shirt in stock, so your cart has 15.", message
  end

  test "can't add out-of-stock, unpriced or zero quantities" do
    assert_raises(ArgumentError) { @cart.add(products(:hoodie), 1) }
    assert_raises(ArgumentError) { @cart.add(Product.create!(category: "accessories", name: "Free", inventory_count: 5), 1) }
    assert_raises(ArgumentError) { @cart.add(@tshirt, 0) }
  end

  test "totals" do
    assert_equal 2, @cart.item_count
    assert_equal 3998, @cart.subtotal_cents
  end

  test "merge moves a visitor cart in, capped at stock, and empties it" do
    session = { cart: { products(:tshirt).id.to_s => 14 } }
    visitor = VisitorCart.new(session)

    @cart.merge!(visitor)

    assert_equal 15, @cart.cart_items.find_by(product: @tshirt).quantity
    assert_nil session[:cart]
  end

  test "problems when stock or price changed after adding" do
    assert_empty @cart.problems

    @tshirt.update!(inventory_count: 1)
    assert_equal [ "Only 1 T-Shirt left. Lower the quantity to check out." ], @cart.problems

    @tshirt.update!(inventory_count: 0)
    assert_match "out of stock", @cart.problems.first

    @tshirt.update!(inventory_count: 5, price_cents: 0)
    assert_match "isn't for sale", @cart.problems.first
  end
end

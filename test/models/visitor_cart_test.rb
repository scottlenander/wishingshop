require "test_helper"

class VisitorCartTest < ActiveSupport::TestCase
  setup do
    @session = {}
    @cart = VisitorCart.new(@session)
    @tshirt = products(:tshirt)
  end

  test "stores product ids and quantities in the session" do
    @cart.add(@tshirt, 2)
    @cart.add(@tshirt, 1)

    assert_equal({ @tshirt.id.to_s => 3 }, @session[:cart])
    assert_equal 3, @cart.item_count
    assert_equal 5997, @cart.subtotal_cents
    assert_equal [ [ @tshirt, 3 ] ], @cart.items.map { |i| [ i.product, i.quantity ] }
  end

  test "adding is capped at stock, like a saved cart" do
    item, message = @cart.add(@tshirt, 99)
    assert_equal 15, item.quantity
    assert_match "Only 15 T-Shirt in stock", message
    assert_raises(ArgumentError) { @cart.add(products(:hoodie), 1) }
  end

  test "update, remove and clear" do
    @cart.add(@tshirt, 2)
    item = @cart.find_item(@tshirt.id)

    @cart.set_quantity(item, 4)
    assert_equal 4, @cart.find_item(@tshirt.id).quantity

    @cart.remove(item)
    assert @cart.empty?
    assert_nil @session[:cart]

    assert_raises(ActiveRecord::RecordNotFound) { @cart.find_item(@tshirt.id) }
  end

  test "skips deleted products and ignores junk in the cookie" do
    @session[:cart] = { @tshirt.id.to_s => 2, "999999" => 1, "abc" => 3, products(:hoodie).id.to_s => -4 }
    assert_equal [ @tshirt ], @cart.items.map(&:product)
  end

  test "limits the number of different products" do
    @session[:cart] = (1..VisitorCart::MAX_LINES).to_h { |i| [ (1_000_000 + i).to_s, 1 ] }
    error = assert_raises(ArgumentError) { @cart.add(@tshirt, 1) }
    assert_match "cart is full", error.message
  end

  test "problems work the same as a saved cart" do
    @cart.add(@tshirt, 3)
    @tshirt.update!(inventory_count: 1)
    assert_equal [ "Only 1 T-Shirt left. Lower the quantity to check out." ], VisitorCart.new(@session).problems
  end
end

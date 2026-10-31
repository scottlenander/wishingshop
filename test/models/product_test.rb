require "test_helper"

class ProductTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test "sends email notifications when back in stock" do
    product = products(:tshirt)

    # Set product out of stock
    product.update(inventory_count: 0)

    assert_emails 2 do
      product.update(inventory_count: 99)
    end
  end

  test "purchase! lowers stock and records an order" do
    product = products(:tshirt)

    order = assert_difference("Order.count", 1) { product.purchase!(users(:one), 3) }

    assert_equal 12, product.inventory_count
    assert_equal 12, product.reload.inventory_count
    assert_equal users(:one), order.user
    assert_equal "T-Shirt", order.product_name
    assert_equal 3, order.quantity
  end

  test "purchase! can buy the last items" do
    product = products(:tshirt)
    product.purchase!(users(:one), 15)
    assert_equal 0, product.reload.inventory_count
  end

  test "purchase! refuses more than is in stock and changes nothing" do
    product = products(:tshirt)

    assert_no_difference("Order.count") do
      assert_raises(Product::NotEnoughStock) { product.purchase!(users(:one), 16) }
    end
    assert_equal 15, product.reload.inventory_count
  end

  test "purchase! rejects a quantity below 1 or not a number" do
    product = products(:tshirt)

    [ 0, -1, "abc", nil ].each do |quantity|
      assert_raises(ArgumentError) { product.purchase!(users(:one), quantity) }
    end
    assert_equal 15, product.reload.inventory_count
  end

  test "deleting a product keeps its order history" do
    order = orders(:one_tshirt)
    products(:tshirt).destroy

    order.reload
    assert_nil order.product
    assert_equal "T-Shirt", order.product_name
  end

  test "SKU is upper-cased and stripped" do
    product = Product.create!(name: "Cap", sku: " cap-1 ")
    assert_equal "CAP-1", product.sku
  end

  test "SKU defaults from the name" do
    assert_equal "BASEBALL-CAP", Product.create!(name: "Baseball Cap").sku
  end

  test "SKU must be unique and use letters, numbers and dashes" do
    assert_not Product.new(name: "Copy", sku: "T-SHIRT").valid?
    assert_not Product.new(name: "Bad", sku: "BAD SKU").valid?
  end
end

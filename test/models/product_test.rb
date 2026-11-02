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

  test "take_stock! lowers stock" do
    Product.take_stock!(products(:tshirt).id, 3)
    assert_equal 12, products(:tshirt).reload.inventory_count
  end

  test "take_stock! can take the last items" do
    Product.take_stock!(products(:tshirt).id, 15)
    assert_equal 0, products(:tshirt).reload.inventory_count
  end

  test "take_stock! refuses more than is in stock and changes nothing" do
    error = assert_raises(Product::NotEnoughStock) { Product.take_stock!(products(:tshirt).id, 16) }
    assert_equal "Only 15 T-Shirt left in stock", error.message
    assert_equal 15, products(:tshirt).reload.inventory_count
  end

  test "price is read and written in dollars and stored in cents" do
    product = Product.new(name: "Cap")
    product.price = "19.99"
    assert_equal 1999, product.price_cents
    assert_equal BigDecimal("19.99"), product.price

    product.price = "$1,250"
    assert_equal 125_000, product.price_cents
  end

  test "an invalid price is an error" do
    product = Product.new(name: "Cap", price: "lots")
    assert_not product.valid?
    assert_includes product.errors.full_messages, "Price must be a dollar amount like 19.99"
  end

  test "only priced products are for sale" do
    assert products(:tshirt).for_sale?
    assert_not Product.new(name: "Free", price_cents: 0).for_sale?
  end

  test "deleting a product keeps its order history" do
    item = order_items(:one_tshirt)
    products(:tshirt).destroy

    item.reload
    assert_nil item.product
    assert_equal "T-Shirt", item.product_name
    assert_equal 1999, item.unit_price_cents
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

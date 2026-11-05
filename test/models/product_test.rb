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

  test "deactivated users get no back-in-stock email" do
    users(:one).deactivate!

    assert_no_emails do
      products(:hoodie).update!(inventory_count: 5)
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
    product = Product.new(category: "accessories", name: "Cap")
    product.price = "19.99"
    assert_equal 1999, product.price_cents
    assert_equal BigDecimal("19.99"), product.price

    product.price = "$1,250"
    assert_equal 125_000, product.price_cents
  end

  test "an invalid price is an error" do
    product = Product.new(category: "accessories", name: "Cap", price: "lots")
    assert_not product.valid?
    assert_includes product.errors.full_messages, "Price must be a dollar amount like 19.99"
  end

  test "only priced products are for sale" do
    assert products(:tshirt).for_sale?
    assert_not Product.new(category: "accessories", name: "Free", price_cents: 0).for_sale?
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
    product = Product.create!(category: "accessories", name: "Cap", sku: " cap-1 ")
    assert_equal "CAP-1", product.sku
  end

  test "SKU defaults from the name" do
    assert_equal "BASEBALL-CAP", Product.create!(category: "accessories", name: "Baseball Cap").sku
  end

  test "SKU must be unique and use letters, numbers and dashes" do
    assert_not Product.new(category: "accessories", name: "Copy", sku: "T-SHIRT").valid?
    assert_not Product.new(category: "accessories", name: "Bad", sku: "BAD SKU").valid?
  end

  test "a category is required and must be one of the list" do
    product = Product.new(name: "Hat", sku: "HAT")
    assert_not product.valid?
    assert_includes product.errors.full_messages, "Category can't be blank"

    product.category = "shoes"
    assert_not product.valid?
    assert_includes product.errors.full_messages, "Category must be one of: Tops, Bottoms, Accessories, Jackets, Hats"

    product.category = "hats"
    assert product.valid?
    assert_equal "Hats", product.category_label
  end

  test "grouped_by_category follows the category order, sorts by name and skips empty groups" do
    cap = Product.create!(name: "cap", category: "hats")
    belt = Product.create!(name: "Belt", category: "accessories")
    groups = Product.grouped_by_category([ cap, products(:tshirt), belt, products(:hoodie) ])

    assert_equal [ [ "tops", "Tops", [ products(:hoodie), products(:tshirt) ] ],
                   [ "accessories", "Accessories", [ belt ] ],
                   [ "hats", "Hats", [ cap ] ] ], groups
  end

  test "products saved before categories existed are grouped last, under Other" do
    products(:hoodie).update_column(:category, nil)
    groups = Product.grouped_by_category([ products(:hoodie), products(:tshirt) ])

    assert_equal [ [ "tops", "Tops", [ products(:tshirt) ] ], [ "other", "Other", [ products(:hoodie) ] ] ], groups
    assert_equal "Other", products(:hoodie).category_label
  end
end

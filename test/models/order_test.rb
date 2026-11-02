require "test_helper"

class OrderTest < ActiveSupport::TestCase
  test "gets a unique number and placed time" do
    order = users(:one).orders.create!(order_items: [ OrderItem.new(product_name: "Hat", quantity: 1) ])
    assert_match(/\AWS-[A-Z0-9]{6}\z/, order.number)
    assert order.placed_at.present?
    assert_equal order.number, order.to_param
  end

  test "needs at least one item" do
    assert_not users(:one).orders.new.valid?
  end

  test "summaries" do
    order = orders(:one_tshirt)
    assert_equal 2, order.item_count
    assert_equal "Visa ending 4242", order.payment_summary
    assert_equal [ "Olive One", "1 Main St", "Springfield, IL 62701" ], order.address_lines
    assert_equal "Standard", order.shipping_option.label
    assert_not order.legacy?
    assert orders(:one_legacy).legacy?
  end
end

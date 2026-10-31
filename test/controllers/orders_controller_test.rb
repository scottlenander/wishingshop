require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @product = products(:tshirt)
  end

  test "visitors are sent to sign in to buy" do
    assert_no_difference("Order.count") { post product_orders_path(@product), params: { quantity: 1 } }
    assert_redirected_to new_session_path
  end

  test "a standard user can buy" do
    sign_in_as users(:one)

    assert_difference("Order.count", 1) { post product_orders_path(@product), params: { quantity: 2 } }
    assert_redirected_to product_path(@product)
    assert_equal "Purchased 2 × T-Shirt.", flash[:notice]
    assert_equal 13, @product.reload.inventory_count
  end

  test "buying more than is in stock is refused" do
    sign_in_as users(:one)

    assert_no_difference("Order.count") { post product_orders_path(@product), params: { quantity: 99 } }
    assert_redirected_to product_path(@product)
    assert_match "left in stock", flash[:alert]
    assert_equal 15, @product.reload.inventory_count
  end

  test "an invalid quantity is refused" do
    sign_in_as users(:one)

    assert_no_difference("Order.count") { post product_orders_path(@product), params: { quantity: 0 } }
    assert flash[:alert].present?
  end

  test "my orders shows only my orders" do
    sign_in_as users(:one)

    get orders_path
    assert_response :success
    assert_select "tr##{ActionView::RecordIdentifier.dom_id(orders(:one_tshirt))}"
    assert_select "tr##{ActionView::RecordIdentifier.dom_id(orders(:two_tshirt))}", count: 0
  end
end

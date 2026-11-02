require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  test "visitors are sent to sign in" do
    get orders_path
    assert_redirected_to new_session_path
  end

  test "my orders shows only my orders, newest first" do
    sign_in_as users(:one)

    get orders_path
    assert_response :success
    assert_select "tbody tr", 2
    assert_select "tbody tr:first-child a", text: "WS-ONE001"
    assert_select "td", text: "$44.97"
    assert_select "td", text: "Price not recorded"
    assert_select "a", text: "WS-TWO001", count: 0
  end

  test "shows my order's details" do
    sign_in_as users(:one)

    get order_path(orders(:one_tshirt))
    assert_response :success
    assert_select "h1", text: "Order WS-ONE001"
    assert_select ".order__address", text: /1 Main St/
    assert_select ".order__payment", text: "Visa ending 4242"
    assert_select ".order__total", text: "$44.97"
    # Fixture order has no billing address; new orders show "Same as shipping" when they match.
  end

  test "a legacy order says prices weren't recorded" do
    sign_in_as users(:one)
    get order_path(orders(:one_legacy))
    assert_select "p", text: /prices weren't recorded/
  end

  test "someone else's order is not found" do
    sign_in_as users(:one)
    get order_path(orders(:two_tshirt))
    assert_response :not_found
  end
end

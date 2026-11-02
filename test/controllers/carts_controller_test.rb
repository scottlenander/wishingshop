require "test_helper"

class CartsControllerTest < ActionDispatch::IntegrationTest
  test "a visitor's cart starts empty" do
    get cart_path
    assert_response :success
    assert_select "p", text: /Your cart is empty/
  end

  test "shows items, subtotal and the free shipping hint" do
    sign_in_as users(:one)

    get cart_path
    assert_select ".cart__name", text: "T-Shirt"
    assert_select ".cart__subtotal", text: "$39.98"
    assert_select ".cart__shipping-note", text: /Add \$10\.02 more for free standard shipping/
    assert_select "a.cart__checkout[href='#{checkout_path}']"
  end

  test "problems disable checkout" do
    products(:tshirt).update!(inventory_count: 1)
    sign_in_as users(:one)

    get cart_path
    assert_select ".cart__problem", text: /Only 1 T-Shirt left/
    assert_select "button.cart__checkout[disabled]"
  end
end

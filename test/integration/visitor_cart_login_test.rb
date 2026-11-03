require "test_helper"

# A visitor's cart lives in the session cookie until they log in, then moves
# into their saved cart. Covers the whole flow across requests.
class VisitorCartLoginTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:two) # no saved cart in the fixtures
    @tshirt = products(:tshirt) # 15 in stock
  end

  test "the visitor's items move into the saved cart at login, and the cookie cart empties" do
    post cart_items_path, params: { product_id: @tshirt.id, quantity: 2 }
    assert_equal "Added 2 × T-Shirt to your cart.", flash[:notice]

    post session_path, params: { email_address: @user.email_address, password: "password" }
    assert_equal 2, @user.reload.cart.cart_items.find_by(product: @tshirt).quantity

    # Logging out shows an empty visitor cart: nothing was left behind in the cookie.
    delete session_path
    get cart_path
    assert_select ".cart__item", 0
  end

  test "items already in the saved cart are added to, capped at stock" do
    @user.create_cart!.cart_items.create!(product: @tshirt, quantity: 10)

    post cart_items_path, params: { product_id: @tshirt.id, quantity: 9 }
    post session_path, params: { email_address: @user.email_address, password: "password" }

    assert_equal 15, @user.reload.cart.cart_items.find_by(product: @tshirt).quantity
  end

  test "products that sold out while the visitor shopped are left out" do
    post cart_items_path, params: { product_id: @tshirt.id, quantity: 1 }
    @tshirt.update!(inventory_count: 0)

    post session_path, params: { email_address: @user.email_address, password: "password" }
    assert_empty @user.reload.cart&.cart_items.to_a
  end

  test "checkout as a visitor asks for login, then comes back to checkout with the items" do
    post cart_items_path, params: { product_id: @tshirt.id, quantity: 1 }
    get checkout_path
    assert_redirected_to new_session_path

    post session_path, params: { email_address: @user.email_address, password: "password" }
    assert_redirected_to checkout_url
    follow_redirect!
    assert_response :success
    assert_match "1 × T-Shirt", response.body
  end
end

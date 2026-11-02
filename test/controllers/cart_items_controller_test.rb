require "test_helper"

class CartItemsControllerTest < ActionDispatch::IntegrationTest
  test "a visitor's cart is kept in the session, not the database" do
    assert_no_difference(%w[ Cart.count CartItem.count ]) do
      post cart_items_path, params: { product_id: products(:tshirt).id, quantity: 2 }
    end
    assert_redirected_to product_path(products(:tshirt))
    assert_equal "Added 2 × T-Shirt to your cart.", flash[:notice]
    assert_equal({ products(:tshirt).id.to_s => 2 }, session[:cart])

    get cart_path
    assert_select ".cart__name", text: "T-Shirt"
    assert_select "nav .layouts-application__cart-count", text: "2"
  end

  test "a visitor updates and removes items by product" do
    tshirt = products(:tshirt)
    post cart_items_path, params: { product_id: tshirt.id, quantity: 2 }

    patch cart_item_path(tshirt.id), params: { quantity: 5 }
    assert_redirected_to cart_path
    assert_equal 5, session[:cart][tshirt.id.to_s]

    delete cart_item_path(tshirt.id)
    assert_nil session[:cart]
  end

  test "a visitor can't change an item that isn't in their cart" do
    patch cart_item_path(products(:tshirt).id), params: { quantity: 1 }
    assert_response :not_found
  end

  test "adding more than in stock is capped" do
    sign_in_as users(:two)
    post cart_items_path, params: { product_id: products(:tshirt).id, quantity: 99 }
    assert_match "Only 15 T-Shirt in stock", flash[:alert]
    assert_equal 15, users(:two).cart.cart_items.first.quantity
  end

  test "out-of-stock items can't be added" do
    post cart_items_path, params: { product_id: products(:hoodie).id, quantity: 1 }
    assert_equal "Hoodie is out of stock", flash[:alert]
  end

  test "updates and removes items in my cart" do
    sign_in_as users(:one)
    item = cart_items(:one_tshirt)

    patch cart_item_path(item), params: { quantity: 4 }
    assert_redirected_to cart_path
    assert_equal 4, item.reload.quantity

    patch cart_item_path(item), params: { quantity: 0 }
    assert_not CartItem.exists?(item.id)
  end

  test "deletes an item" do
    sign_in_as users(:one)
    assert_difference("CartItem.count", -1) { delete cart_item_path(cart_items(:one_tshirt)) }
  end

  test "another cart's items are not found" do
    sign_in_as users(:two)
    patch cart_item_path(cart_items(:one_tshirt)), params: { quantity: 1 }
    assert_response :not_found
    assert_no_difference("CartItem.count") { delete cart_item_path(cart_items(:one_tshirt)) }
  end
end

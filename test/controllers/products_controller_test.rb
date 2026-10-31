require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @product = products(:tshirt)
  end

  test "visitors can browse but are sent to sign in to change products" do
    get products_path
    assert_response :success

    get new_product_path
    assert_redirected_to new_session_path
  end

  test "standard users can't create, edit or delete products" do
    sign_in_as users(:one)

    get new_product_path
    assert_redirected_to root_path
    assert_equal "You're not authorized to do that.", flash[:alert]

    patch product_path(@product), params: { product: { inventory_count: 99 } }
    assert_redirected_to root_path
    assert_equal 15, @product.reload.inventory_count

    assert_no_difference("Product.count") { delete product_path(@product) }
  end

  test "standard users don't see product admin buttons" do
    sign_in_as users(:one)

    get product_path(@product)
    assert_select "a", text: "Edit", count: 0
    assert_select "a", text: "Users", count: 0
  end

  test "admins can edit stock" do
    sign_in_as users(:admin)

    get product_path(@product)
    assert_select "a", text: "Edit"

    patch product_path(@product), params: { product: { inventory_count: 42 } }
    assert_redirected_to product_path(@product)
    assert_equal 42, @product.reload.inventory_count
  end

  test "admins can create and delete products" do
    sign_in_as users(:admin)

    assert_difference("Product.count", 1) do
      post products_path, params: { product: { name: "Socks", inventory_count: 3 } }
    end
    assert_difference("Product.count", -1) { delete product_path(Product.last) }
  end

  test "visitors see log in to buy and the email form" do
    get product_path(@product)
    assert_select "a", text: "Log in to buy"

    get product_path(products(:hoodie))
    assert_select "input[type=email][placeholder='you@example.com']"
  end

  test "signed-in users see buy, notify me and unsubscribe" do
    sign_in_as users(:two)
    get product_path(@product)
    assert_select "input[type=submit][value=Buy]"

    get product_path(products(:hoodie))
    assert_select "button", text: "Notify me"

    sign_in_as users(:one) # already subscribed to Hoodie
    get product_path(products(:hoodie))
    assert_select "button", text: "Unsubscribe"
  end
end

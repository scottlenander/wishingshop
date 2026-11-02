require "test_helper"

class Admin::FeaturedProductsControllerTest < ActionDispatch::IntegrationTest
  def pick_params(product, from: 1.minute.ago, to: 1.day.from_now)
    { featured_product: { product_id: product.id, starts_at: from, ends_at: to } }
  end

  test "standard users are turned away" do
    sign_in_as users(:one)
    get admin_featured_products_path
    assert_redirected_to root_path
    assert_no_difference("FeaturedProduct.count") { post admin_featured_products_path, params: pick_params(products(:tshirt)) }
  end

  test "index shows the random pick when there's no admin pick" do
    sign_in_as users(:admin)
    get admin_featured_products_path
    assert_response :success
    assert_select ".admin-featured__current", text: /Random today: T-Shirt/
  end

  test "new pre-selects the product from the shortcut" do
    sign_in_as users(:admin)
    get new_admin_featured_product_path(product_id: products(:hoodie).id)
    assert_select "select[name='featured_product[product_id]'] option[selected][value='#{products(:hoodie).id}']"
  end

  test "creates a pick and records the admin" do
    sign_in_as users(:admin)
    assert_difference("FeaturedProduct.count", 1) { post admin_featured_products_path, params: pick_params(products(:hoodie)) }
    assert_redirected_to admin_featured_products_path
    assert_equal users(:admin), FeaturedProduct.last.user
    assert_equal [ products(:hoodie), :admin ], FeaturedProduct.product_for
  end

  test "an overlapping pick is refused" do
    sign_in_as users(:admin)
    post admin_featured_products_path, params: pick_params(products(:hoodie))

    assert_no_difference("FeaturedProduct.count") do
      post admin_featured_products_path, params: pick_params(products(:tshirt), from: 1.hour.from_now, to: 2.days.from_now)
    end
    assert_response :unprocessable_entity
    assert_select "p.error", text: /Overlaps with Hoodie/
  end

  test "updates and removes a pick" do
    sign_in_as users(:admin)
    pick = featured_products(:last_month)
    patch admin_featured_product_path(pick), params: { featured_product: { product_id: products(:tshirt).id } }
    assert_equal products(:tshirt), pick.reload.product

    assert_difference("FeaturedProduct.count", -1) { delete admin_featured_product_path(pick) }
  end
end

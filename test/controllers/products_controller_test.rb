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
    assert_select ".products-show__actions", count: 0
    assert_select ".products-show__info a", text: "Edit", count: 0
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

  test "visitors see the price, add to cart and the email form" do
    get product_path(@product)
    assert_select ".products-inventory__price", text: "$19.99"
    assert_select "input[type=submit][value='Add to cart']"

    get product_path(products(:hoodie))
    assert_select "input[type=email][placeholder='you@example.com']"
  end

  test "signed-in users see buy, notify me and unsubscribe" do
    sign_in_as users(:two)
    get product_path(@product)
    assert_select "input[type=submit][value='Add to cart']"

    get product_path(products(:hoodie))
    assert_select "button", text: "Notify me"

    sign_in_as users(:one) # already subscribed to Hoodie
    get product_path(products(:hoodie))
    assert_select "button", text: "Unsubscribe"
  end

  test "homepage shows live announcements in the carousel" do
    get products_path
    assert_select "section.carousel[aria-roledescription=carousel]" do
      assert_select "[aria-roledescription=slide]", 2
      assert_select ".carousel__title", text: "Big T-Shirt sale"
      assert_select ".carousel__title", text: "Coming soon", count: 0
      assert_select "button.carousel__dot", 2
    end
  end

  test "homepage hides the carousel when nothing is live" do
    Announcement.destroy_all
    get products_path
    assert_select "section.carousel", count: 0
    assert_select ".products-index__hero--single .products-featured"
  end

  test "homepage shows the admin featured pick" do
    FeaturedProduct.create!(product: products(:hoodie), starts_at: 1.hour.ago, ends_at: 1.hour.from_now)
    get products_path
    assert_select ".products-featured" do
      assert_select "h2", text: "Hoodie"
      assert_select ".products-featured__note", text: "Picked by our team"
      assert_select ".products-inventory__status", text: "Out of stock"
    end
  end

  test "homepage shows a random featured product without the admin note" do
    get products_path
    assert_select ".products-featured h2", text: "T-Shirt"
    assert_select ".products-featured__note", count: 0
  end

  test "admins see a feature this product button" do
    sign_in_as users(:admin)
    get product_path(@product)
    assert_select "a[href='#{new_admin_featured_product_path(product_id: @product.id)}']", text: "Feature this product"
  end

  test "the nav shows Login when signed out" do
    get products_path
    assert_select "nav a[href='#{new_session_path}']", text: "Login"
    assert_select "nav .layouts-application__greeting", count: 0
  end

  test "the nav greets the signed-in user by first name" do
    sign_in_as users(:one)
    get products_path
    assert_select "nav .layouts-application__greeting", text: "Hi, Olive!"
    assert_select "nav button", text: "Log out"
    assert_select "a", text: "Login", count: 0
  end

  test "the nav brand is WishingShop and links home" do
    get products_path
    assert_select "nav a.layouts-application__brand[href='#{root_path}']", text: "WishingShop" do
      assert_select "svg[aria-hidden=true]"
    end
  end

  test "the tab title is the site name, after the page title" do
    get products_path
    assert_select "title", text: "WishingShop"

    sign_in_as users(:admin)
    get admin_users_path
    assert_select "title", text: "Users · WishingShop"
  end

  test "the product page shows the 3 newest reviews, a summary and show more" do
    4.times do |i|
      user = User.create!(email_address: "x#{i}@example.com", password: "password", first_name: "X#{i}", last_name: "Y")
      user.orders.create!(order_items: [ OrderItem.new(product: @product, product_name: "T-Shirt", quantity: 1) ])
      @product.reviews.create!(user: user, rating: 5, body: "Newer review #{i} text.", created_at: i.hours.ago)
    end

    get product_path(@product)
    assert_select ".reviews-item", 3
    assert_select ".reviews-item:first-child .reviews-item__body", text: /Newer review 0/
    assert_select ".reviews-summary__count", text: "5 reviews"
    assert_select ".reviews-summary__average strong", text: "4.8 out of 5"
    assert_select "[role=meter][aria-label='5 stars: 4 reviews']"
    assert_select "turbo-frame#reviews_from_3 a", text: "Show more reviews (2 more)"
  end

  test "what each user sees in the review box" do
    get product_path(@product)
    assert_select "#write-review a", text: "Log in to write a review"

    sign_in_as users(:admin)
    get product_path(@product)
    assert_select "#write-review", text: /Only customers who bought this can review it/

    sign_in_as users(:two)
    get product_path(@product)
    assert_select "#write-review form.reviews-form"
    assert_select "#write-review input[type=radio][name='review[rating]']", 5

    sign_in_as users(:one)
    get product_path(@product)
    assert_select "#write-review h3", text: "Your review"
    assert_select "#write-review a", text: "Edit"
  end

  test "product cards show the rating, or not yet rated, to visitors too" do
    get products_path

    tshirt = css_select(".products-index__card").find { |card| card.text.include?("T-Shirt") }
    assert_equal 1, tshirt.css("[role=img][aria-label='Rated 4.0 out of 5 from 1 review']").size
    assert_includes tshirt.text, "4.0 (1)"

    hoodie = css_select(".products-index__card").find { |card| card.text.include?("Hoodie") }
    assert_includes hoodie.css(".products-index__card-unrated").text, "Not yet rated"
  end
end

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

  test "a deactivated user's reviews still show" do
    users(:one).deactivate!
    get product_path(products(:tshirt))

    assert_select ".reviews-item", text: /Soft and fits well/
    assert_select ".reviews-item", text: /Olive O\./
  end

  def add_rated_reviews(*ratings)
    ratings.each_with_index do |rating, i|
      user = User.create!(email_address: "rated#{i}@example.com", password: "password", first_name: "Rated#{i}", last_name: "User")
      user.orders.create!(order_items: [ OrderItem.new(product: @product, product_name: "T-Shirt", quantity: 1) ])
      @product.reviews.create!(user: user, rating: rating, body: "A #{rating} star review #{i}.", created_at: (i + 1).hours.ago)
    end
  end

  test "the product page shows the rating under the title, linking to the reviews" do
    get product_path(@product)
    assert_select ".products-show__rating a[href='#reviews']", text: /4.0 out of 5 · 1 review/

    get product_path(products(:hoodie))
    assert_select ".products-show__rating", text: "Not yet rated"
  end

  test "the featured card shows its rating" do
    FeaturedProduct.create!(product: @product, starts_at: 1.hour.ago, ends_at: 1.hour.from_now)
    get products_path
    assert_select ".products-featured [role=img][aria-label=?]", "Rated 4.0 out of 5 from 1 review"

    FeaturedProduct.delete_all
    FeaturedProduct.create!(product: products(:hoodie), starts_at: 1.hour.ago, ends_at: 1.hour.from_now)
    get products_path
    assert_select ".products-featured .products-index__card-unrated", text: "Not yet rated"
  end

  test "reviews can be sorted by stars" do
    add_rated_reviews(2, 5)

    get product_path(@product, sort: "highest")
    assert_select ".reviews-item:first-child [role=img][aria-label=?]", "5 out of 5 stars"
    assert_select ".reviews__sort a[aria-current=true]", text: "Highest rated"

    get product_path(@product, sort: "lowest")
    assert_select ".reviews-item:first-child [role=img][aria-label=?]", "2 out of 5 stars"
  end

  test "the star bars filter the list, and Show all clears it" do
    add_rated_reviews(5, 5, 2)

    get product_path(@product)
    assert_select "a.reviews-summary__label[aria-label=?][href=?]", "5 stars: show only these 2 reviews",
                  product_path(@product, stars: 5, anchor: "reviews")
    assert_select ".reviews-summary__row span.reviews-summary__label", text: "3 stars" # no reviews: not a link

    get product_path(@product, stars: 5, sort: "lowest")
    assert_select ".reviews-item", 2
    assert_select ".reviews__filter", text: /Showing 2 5-star reviews/
    assert_select ".reviews__filter a[href=?]", product_path(@product, sort: "lowest", anchor: "reviews"), text: "Show all reviews"
    assert_select ".reviews__sort a[href=?]", product_path(@product, sort: "highest", stars: 5, anchor: "reviews")
  end

  test "a star level with no reviews, or bad params, still shows a sensible page" do
    get product_path(@product, stars: 1)
    assert_select ".reviews__empty", text: "No 1-star reviews yet."

    get product_path(@product, stars: 9, sort: "sideways")
    assert_select ".reviews-item", 1
    assert_select ".reviews__filter", count: 0
    assert_select ".reviews__sort a[aria-current=true]", text: "Newest"
  end
end

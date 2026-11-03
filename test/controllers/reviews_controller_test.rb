require "test_helper"

class ReviewsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @product = products(:tshirt)
  end

  def add_reviews(count)
    count.times do |i|
      user = User.create!(email_address: "r#{i}@example.com", password: "password", first_name: "Rev#{i}", last_name: "Iewer")
      user.orders.create!(order_items: [ OrderItem.new(product: @product, product_name: "T-Shirt", quantity: 1) ])
      @product.reviews.create!(user: user, rating: 3, body: "Review number #{i} is here.", created_at: (i + 3).days.ago)
    end
  end

  test "a buyer posts a review" do
    sign_in_as users(:two)

    assert_difference("Review.count", 1) do
      post product_reviews_path(@product), params: { review: { rating: 5, body: "Best shirt I own." } }
    end
    assert_redirected_to product_path(@product, anchor: "reviews")
    assert_equal "Thanks for your review!", flash[:notice]
  end

  test "errors show the product page again with the text kept" do
    sign_in_as users(:two)

    post product_reviews_path(@product), params: { review: { rating: "", body: "Too short" } }
    assert_response :unprocessable_entity
    assert_select ".reviews-form .error", text: /Rating must be 1 to 5 stars/
    assert_select "textarea[name='review[body]']", text: "Too short"
  end

  test "a non-buyer can't post" do
    sign_in_as users(:admin)
    assert_no_difference("Review.count") do
      post product_reviews_path(@product), params: { review: { rating: 5, body: "I never bought this." } }
    end
    assert_response :unprocessable_entity
    assert_select "#write-review", text: /Only customers who bought this can review it/
    assert_select "#write-review form", count: 0
  end

  test "a visitor is sent to log in, then back to the review form" do
    get new_product_review_path(@product)
    assert_redirected_to new_session_path

    post session_path, params: { email_address: "two@example.com", password: "password" }
    assert_redirected_to new_product_review_url(@product)
    follow_redirect!
    assert_redirected_to product_path(@product, anchor: "write-review")
  end

  test "the author edits their review" do
    sign_in_as users(:one)
    review = reviews(:one_tshirt)

    get edit_product_review_path(@product, review)
    assert_response :success

    patch product_review_path(@product, review), params: { review: { rating: 2, body: "Shrank in the wash." } }
    assert_redirected_to product_path(@product, anchor: "reviews")
    assert_equal 2, review.reload.rating
  end

  test "someone else's review can't be edited or deleted" do
    sign_in_as users(:two)
    get edit_product_review_path(@product, reviews(:one_tshirt))
    assert_response :not_found

    assert_no_difference("Review.count") { delete product_review_path(@product, reviews(:one_tshirt)) }
    assert_response :not_found
  end

  test "the author or an admin can delete" do
    sign_in_as users(:one)
    assert_difference("Review.count", -1) { delete product_review_path(@product, reviews(:one_tshirt)) }

    add_reviews(1)
    sign_in_as users(:admin)
    assert_difference("Review.count", -1) { delete product_review_path(@product, @product.reviews.first) }
  end

  test "show more returns the next page and a link for the rest" do
    add_reviews(14) # 15 with the fixture

    get product_reviews_path(@product, offset: 3)
    assert_response :success
    assert_select "turbo-frame#reviews_from_3 .reviews-item", 10
    assert_select "turbo-frame#reviews_from_3 turbo-frame#reviews_from_13 a", text: "Show more reviews (2 more)"

    get product_reviews_path(@product, offset: 13)
    assert_select "turbo-frame#reviews_from_13 .reviews-item", 2
    assert_select "turbo-frame#reviews_from_15", count: 0
  end
end

require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  def review(**overrides)
    Review.new({ user: users(:two), product: products(:tshirt), rating: 5, body: "Great shirt, would buy again." }.merge(overrides))
  end

  test "a buyer can review" do
    assert review.valid?
  end

  test "rating must be 1 to 5" do
    [ 0, 6, nil ].each do |rating|
      assert_includes review(rating: rating).tap(&:valid?).errors.full_messages, "Rating must be 1 to 5 stars"
    end
  end

  test "text must be 10 to 2000 characters, tidied" do
    assert_includes review(body: "Nice").tap(&:valid?).errors.full_messages, "Review is too short (at least 10 characters)"
    assert_not review(body: "x" * 2001).valid?
    assert_equal "Lots of space", review(body: "  Lots   of space  ").body
  end

  test "only one review per user per product" do
    duplicate = review(user: users(:one))
    assert_not duplicate.valid?
    assert_includes duplicate.errors.full_messages, "You've already reviewed this product"
  end

  test "only buyers can review" do
    non_buyer = review(user: users(:admin))
    assert_not non_buyer.valid?
    assert_includes non_buyer.errors.full_messages, "Only customers who bought this can review it"
  end

  test "orders from before checkout count as purchases" do
    assert review(user: users(:one), product: products(:hoodie)).valid?
  end

  test "author name, edited and newest first" do
    r = reviews(:one_tshirt)
    assert_equal "Olive O.", r.author_name
    assert_not r.edited?
    r.update!(body: "Changed my mind, it's great.")
    assert r.edited?

    newer = review.tap(&:save!)
    assert_equal [ newer, r ], products(:tshirt).reviews.newest_first.to_a
  end

  test "rating summary" do
    review(rating: 2).save!
    summary = products(:tshirt).rating_summary
    assert_equal 3.0, summary.average
    assert_equal 2, summary.count
    assert_equal({ 5 => 0, 4 => 1, 3 => 0, 2 => 1, 1 => 0 }, summary.breakdown)

    empty = products(:hoodie).rating_summary
    assert_nil empty.average
    assert_not empty.any?
  end

  test "ratings for many products in one query" do
    review(rating: 2).save!
    ratings = Product.ratings_for([ products(:tshirt).id, products(:hoodie).id ])
    assert_equal({ products(:tshirt).id => [ 3.0, 2 ] }, ratings)
  end

  test "sorted orders by stars, newest first among equals, and with_stars filters" do
    product = products(:tshirt)
    old_five = Review.new(product: product, user: users(:two), rating: 5, body: "Old five star review.", created_at: 5.days.ago)
    old_five.save!(validate: false)
    new_five = Review.new(product: product, user: users(:admin), rating: 5, body: "New five star review.", created_at: 1.hour.ago)
    new_five.save!(validate: false)
    four = reviews(:one_tshirt)

    assert_equal [ new_five, old_five, four ], product.reviews.sorted("highest").to_a
    assert_equal [ four, new_five, old_five ], product.reviews.sorted("lowest").to_a
    assert_equal [ new_five, four, old_five ], product.reviews.sorted("newest").to_a
    assert_equal [ new_five, four, old_five ], product.reviews.sorted("anything else").to_a
    assert_equal [ new_five, old_five ], product.reviews.with_stars(5).sorted("newest").to_a
    assert_equal 3, product.reviews.with_stars(nil).count
  end
end

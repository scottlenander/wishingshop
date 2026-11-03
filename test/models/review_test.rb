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
end

require "test_helper"

class FeaturedProductTest < ActiveSupport::TestCase
  def pick(product: products(:tshirt), from: 1.hour.ago, to: 1.hour.from_now)
    FeaturedProduct.create!(product: product, starts_at: from, ends_at: to)
  end

  test "ends_at must be after starts_at" do
    record = FeaturedProduct.new(product: products(:tshirt), starts_at: Time.current, ends_at: 1.hour.ago)
    assert_not record.valid?
    assert_includes record.errors[:ends_at], "must be after the start"
  end

  test "picks can't overlap" do
    pick(from: 1.hour.ago, to: 1.day.from_now)

    overlapping = FeaturedProduct.new(product: products(:hoodie), starts_at: 2.hours.from_now, ends_at: 2.days.from_now)
    assert_not overlapping.valid?
    assert_match "Overlaps with T-Shirt", overlapping.errors.full_messages.to_sentence

    back_to_back = FeaturedProduct.new(product: products(:hoodie), starts_at: 1.day.from_now, ends_at: 2.days.from_now)
    assert back_to_back.valid?
  end

  test "an active admin pick wins, even when out of stock" do
    pick(product: products(:hoodie))
    assert_equal [ products(:hoodie), :admin ], FeaturedProduct.product_for
  end

  test "without an active pick, a random in-stock product is chosen" do
    product, source = FeaturedProduct.product_for
    assert_equal :random, source
    assert product.inventory_count.positive?
  end

  test "the random pick is the same all day and can change the next day" do
    5.times { |i| Product.create!(category: "accessories", name: "Sock #{i}", inventory_count: 3) }

    travel_to Time.zone.parse("2026-11-02 08:00") do
      morning = FeaturedProduct.product_for.first
      travel 10.hours
      assert_equal morning, FeaturedProduct.product_for.first
    end

    picks = (1..14).map { |day| FeaturedProduct.random_for(Date.new(2026, 11, day)) }
    assert picks.uniq.size > 1, "expected different products on different days"
  end

  test "the random pick prefers products with an image" do
    with_image = Product.create!(category: "accessories", name: "Pictured", inventory_count: 2)
    with_image.featured_image.attach(io: File.open(file_fixture("pixel.png")), filename: "pixel.png", content_type: "image/png")

    assert_equal with_image, FeaturedProduct.random_for(Date.current)
  end

  test "nothing is featured when no products are in stock" do
    Product.update_all(inventory_count: 0)
    assert_nil FeaturedProduct.product_for
  end
end

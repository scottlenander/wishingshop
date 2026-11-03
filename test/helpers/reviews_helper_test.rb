require "test_helper"

class ReviewsHelperTest < ActionView::TestCase
  test "star_rating draws filled and empty stars with a spoken label" do
    html = Nokogiri::HTML.fragment(star_rating(4))
    span = html.at("span.reviews-stars")

    assert_equal "★★★★☆", span.text
    assert_equal "img", span["role"]
    assert_equal "4 out of 5 stars", span["aria-label"]
  end

  test "star_rating rounds averages and keeps the exact number in the label" do
    assert_equal "★★★★☆", Nokogiri::HTML.fragment(star_rating(4.4)).text
    assert_equal "★★★★★", Nokogiri::HTML.fragment(star_rating(4.5)).text
    assert_equal "4.4 out of 5 stars", Nokogiri::HTML.fragment(star_rating(4.4)).at("span")["aria-label"]
  end

  test "star_rating stays within 0 to 5 stars and takes a custom label" do
    assert_equal "☆☆☆☆☆", Nokogiri::HTML.fragment(star_rating(-1)).text
    assert_equal "★★★★★", Nokogiri::HTML.fragment(star_rating(7)).text
    assert_equal "Rated 3.0", Nokogiri::HTML.fragment(star_rating(3.0, label: "Rated 3.0")).at("span")["aria-label"]
  end

  test "review_list_params leaves out the defaults" do
    assert_equal({}, review_list_params(sort: "newest", stars: nil))
    assert_equal({ sort: "lowest", stars: 2 }, review_list_params(sort: "lowest", stars: 2))
    assert_equal({ stars: 5 }, review_list_params(sort: "newest", stars: 5))
  end
end

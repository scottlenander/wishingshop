module ReviewsHelper
  # Query params for links in the review list: the sort and star filter, leaving
  # out defaults so plain URLs stay plain. e.g. { sort: "highest", stars: 5 }
  def review_list_params(sort:, stars:)
    { sort: (sort unless sort == Review::SORTS.keys.first), stars: stars }.compact
  end

  # "★★★★☆", read out as "4 out of 5 stars".
  def star_rating(rating, label: nil)
    filled = rating.to_f.round.clamp(0, 5)
    tag.span("★" * filled + "☆" * (5 - filled), class: "reviews-stars", role: "img",
                                                 aria: { label: label || "#{rating} out of 5 stars" })
  end
end

module ReviewsHelper
  # "★★★★☆", read out as "4 out of 5 stars".
  def star_rating(rating, label: nil)
    filled = rating.to_f.round.clamp(0, 5)
    tag.span("★" * filled + "☆" * (5 - filled), class: "reviews-stars", role: "img",
                                                 aria: { label: label || "#{rating} out of 5 stars" })
  end
end

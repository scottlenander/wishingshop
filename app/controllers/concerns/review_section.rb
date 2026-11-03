# Loads what the review section of the product page needs. Used by the product
# page and when a new review fails to save (the page is shown again).
module ReviewSection
  extend ActiveSupport::Concern

  private
    def load_review_section(product, new_review: nil)
      @reviews = product.reviews.newest_first.includes(:user).limit(Review::FIRST_PAGE).to_a
      @rating_summary = product.rating_summary
      # authenticated? loads the session on pages visitors can also see.
      user = authenticated? ? Current.user : nil
      @my_review = user && product.reviews.find_by(user: user)
      @can_review = user&.purchased?(product) || false
      @new_review = new_review || Review.new
    end
end

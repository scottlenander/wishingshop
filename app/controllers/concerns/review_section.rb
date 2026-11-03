# Loads what the review section of the product page needs. Used by the product
# page, when a new review fails to save (the page is shown again), and by
# "Show more" (ReviewsController#index), which keeps the same sort and filter.
module ReviewSection
  extend ActiveSupport::Concern

  private
    def load_review_section(product, new_review: nil)
      load_review_list_options
      @reviews = review_list(product).limit(Review::FIRST_PAGE).to_a
      @rating_summary = product.rating_summary
      # How many reviews the current filter shows in total, for "Show more (N more)".
      @review_total = @review_stars ? @rating_summary.breakdown.fetch(@review_stars) : @rating_summary.count
      # authenticated? loads the session on pages visitors can also see.
      user = authenticated? ? Current.user : nil
      @my_review = user && product.reviews.find_by(user: user)
      @can_review = user&.purchased?(product) || false
      @new_review = new_review || Review.new
    end

    # ?sort=highest|lowest and ?stars=1..5. Anything else falls back to newest, all stars.
    def load_review_list_options
      @review_sort = Review::SORTS.key?(params[:sort]) ? params[:sort] : Review::SORTS.keys.first
      stars = Integer(params[:stars], exception: false)
      @review_stars = stars if stars&.between?(1, 5)
    end

    def review_list(product)
      product.reviews.with_stars(@review_stars).sorted(@review_sort).includes(:user)
    end
end

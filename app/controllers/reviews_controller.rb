# Product reviews. Anyone can read them; buyers can write one each and edit or
# delete it; admins can delete any.
class ReviewsController < ApplicationController
  include ReviewSection

  allow_unauthenticated_access only: :index
  before_action :set_product
  before_action :set_own_review, only: %i[ edit update ]

  # "Show more reviews": the next page after `offset`. In a Turbo Frame this is
  # added to the list on the product page; otherwise it's a page of its own.
  def index
    @offset = [ params[:offset].to_i, 0 ].max
    @reviews = @product.reviews.newest_first.includes(:user).offset(@offset).limit(Review::PAGE_SIZE).to_a
    @next_offset = @offset + @reviews.size
    @remaining = @product.reviews.count - @next_offset
  end

  # Visitors are sent to log in first, then come back here and on to the form.
  def new
    redirect_to product_path(@product, anchor: "write-review")
  end

  def create
    @review = Current.user.reviews.new(review_params.merge(product: @product))
    if @review.save
      redirect_to product_path(@product, anchor: "reviews"), notice: "Thanks for your review!"
    else
      render_product_with(@review)
    end
  end

  def edit
  end

  def update
    if @review.update(review_params)
      redirect_to product_path(@product, anchor: "reviews"), notice: "Review updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Authors delete their own; admins can delete anyone's.
    scope = admin? ? @product.reviews : Current.user.reviews.where(product: @product)
    scope.find(params[:id]).destroy
    redirect_to product_path(@product, anchor: "reviews"), notice: "Review deleted."
  end

  private
    def set_product
      @product = Product.find(params[:product_id])
    end

    def set_own_review
      @review = Current.user.reviews.where(product: @product).find(params[:id])
    end

    def review_params
      params.expect(review: %i[ rating body ])
    end

    # Shows the product page again with the form, its errors and the text kept.
    def render_product_with(review)
      load_review_section(@product, new_review: review)
      render "products/show", status: :unprocessable_entity
    end
end

# Back-in-stock sign-ups from the product page. Logged-in users subscribe with
# one click using their account email; visitors type an email.
class SubscribersController < ApplicationController
  allow_unauthenticated_access
  before_action :set_product

  def create
    subscriber = if authenticated?
      # Also claims an earlier visitor sign-up that used this email.
      @product.subscribers.find_or_initialize_by(email: Current.user.email_address).tap do |s|
        s.update(user: Current.user)
      end
    else
      @product.subscribers.where(subscribers_params).first_or_create
    end

    if subscriber.persisted?
      redirect_to @product, notice: "You are now subscribed."
    else
      redirect_to @product, alert: subscriber.errors.full_messages.to_sentence
    end
  end

  private
    def set_product
      @product = Product.find(params[:product_id])
    end

    def subscribers_params
      params.expect(subscriber: [ :email ])
    end
end

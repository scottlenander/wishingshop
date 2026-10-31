# "My subscriptions": the signed-in user's back-in-stock sign-ups.
class SubscriptionsController < ApplicationController
  def index
    @subscriptions = Current.user.subscribers.includes(:product).order(:created_at)
  end

  def destroy
    # Scoped to the current user, so someone else's subscription is a 404.
    subscription = Current.user.subscribers.find(params[:id])
    subscription.destroy
    redirect_back_or_to subscriptions_path, notice: "Unsubscribed from #{subscription.product.name}."
  end
end

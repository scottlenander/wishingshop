# "My orders": the signed-in user's order history.
class OrdersController < ApplicationController
  def index
    @orders = Current.user.orders.includes(:order_items).order(placed_at: :desc)
  end

  def show
    # Scoped to the current user, so someone else's order is a 404.
    @order = Current.user.orders.includes(order_items: { product: { featured_image_attachment: :blob } })
                         .find_by!(number: params[:number])
  end
end

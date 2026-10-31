# Buying products and "My orders". Any signed-in user can buy.
class OrdersController < ApplicationController
  def index
    @orders = Current.user.orders.order(created_at: :desc)
  end

  def create
    product = Product.find(params[:product_id])
    quantity = params.fetch(:quantity, 1)
    order = product.purchase!(Current.user, quantity)
    redirect_to product, notice: "Purchased #{order.quantity} × #{order.product_name}."
  rescue Product::NotEnoughStock, ArgumentError => e
    redirect_to product, alert: e.message
  end
end

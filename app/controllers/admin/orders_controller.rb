# All orders from every user.
class Admin::OrdersController < Admin::BaseController
  def index
    @orders = Order.includes(:user).order(created_at: :desc)
  end
end

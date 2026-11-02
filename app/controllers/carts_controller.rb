# The cart page. Visitors have a cart too; checking out asks them to log in.
class CartsController < ApplicationController
  allow_unauthenticated_access

  def show
    @cart = current_cart
    @items = @cart.items
    @problems = @cart.problems
  end
end

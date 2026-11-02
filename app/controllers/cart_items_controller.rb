# Adding, changing and removing cart lines, for saved and visitor carts.
# Everything is scoped to the current cart, so another cart's items are a 404.
class CartItemsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_item, only: %i[ update destroy ]

  def create
    product = Product.find(params[:product_id])
    quantity = params.fetch(:quantity, 1)
    _item, capped = current_cart.add(product, quantity)
    if capped
      redirect_to product, alert: capped
    else
      redirect_to product, notice: "Added #{quantity.to_i} × #{product.name} to your cart."
    end
  rescue ArgumentError => e
    redirect_to product, alert: e.message
  end

  def update
    quantity = Integer(params[:quantity], exception: false).to_i
    if quantity <= 0
      current_cart.remove(@item)
      redirect_to cart_path, notice: "Removed #{@item.product.name}."
    elsif quantity > @item.product.inventory_count
      current_cart.set_quantity(@item, @item.product.inventory_count)
      redirect_to cart_path, alert: "Only #{@item.product.inventory_count} #{@item.product.name} in stock."
    else
      current_cart.set_quantity(@item, quantity)
      redirect_to cart_path, notice: "Updated #{@item.product.name}."
    end
  end

  def destroy
    current_cart.remove(@item)
    redirect_to cart_path, notice: "Removed #{@item.product.name}."
  end

  private
    def set_item
      # Saved carts use the item id; visitor carts use the product id.
      @item = current_cart.find_item(params[:id])
    end
end

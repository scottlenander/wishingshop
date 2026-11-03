# Checkout: address, shipping method and payment. Login required; a visitor
# who clicks Checkout logs in and comes straight back here.
class CheckoutsController < ApplicationController
  before_action :set_cart

  def show
    @checkout = Checkout.for(Current.user, @cart)
  end

  def create
    @checkout = Checkout.new(checkout_params.merge(user: Current.user, cart: @cart))
    if (order = @checkout.place!)
      redirect_to order_path(order), notice: "Thanks! Your order #{order.number} is placed."
    else
      @checkout.clear_card_secrets
      render :show, status: :unprocessable_entity
    end
  end

  private
    def set_cart
      @cart = current_cart
      redirect_to cart_path, alert: "Your cart is empty." if @cart.empty?
    end

    def checkout_params
      address_fields = Checkout::ADDRESS_FIELDS.flat_map { |field| [ :"bill_#{field}", :"ship_#{field}" ] }
      params.expect(checkout: [ *address_fields, :save_billing, :same_as_billing, :shipping_choice, :save_shipping,
                                :shipping_nickname, :shipping_method, :card_name, :card_number, :card_expiry, :card_cvc ])
    end
end

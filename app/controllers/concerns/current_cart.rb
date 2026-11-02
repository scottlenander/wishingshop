# The cart for whoever is browsing: the signed-in user's saved Cart, or a
# VisitorCart kept in the session cookie. A visitor's cart is merged into the
# user's cart when they log in (see SessionsController#create).
module CurrentCart
  extend ActiveSupport::Concern

  included do
    helper_method :current_cart_count
  end

  private
    def current_cart
      @current_cart ||= if authenticated?
        Current.user.cart || Current.user.create_cart!
      else
        VisitorCart.new(session)
      end
    end

    # Nav badge count, without creating an empty saved cart just to show it.
    def current_cart_count
      if authenticated?
        Current.user.cart&.cart_items&.sum(:quantity).to_i
      else
        VisitorCart.new(session).item_count
      end
    end

    def merge_visitor_cart_into(user)
      (user.cart || user.create_cart!).merge!(VisitorCart.new(session))
    end
end

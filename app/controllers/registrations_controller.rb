# Sign-up: anyone can create a standard account and is logged straight in, with
# their visitor cart kept. New users then get an optional billing address step.
class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  # Shares the login limit (and bin/e2e-server's higher setting).
  rate_limit to: Integer(ENV.fetch("LOGIN_RATE_LIMIT", 10)), within: 3.minutes, only: :create,
             with: -> { redirect_to new_registration_path, alert: "Try again later." }

  def new
    return redirect_to account_path if authenticated?

    @user = User.new
  end

  def create
    @user = User.new(registration_params)
    if @user.save
      start_new_session_for @user
      merge_visitor_cart_into(@user)
      redirect_to after_authentication_url(fallback: new_address_path(kind: "billing", welcome: 1)),
                  notice: "Welcome to WishingShop, #{@user.first_name}!"
    else
      point_to_login
      render :new, status: :unprocessable_entity
    end
  end

  private
    # Only these fields: a sign-up can never make an admin.
    def registration_params
      params.expect(user: [ :first_name, :last_name, :email_address, :password, :password_confirmation ])
    end

    # A closed account's email: its owner should log in to reactivate it.
    def point_to_login
      return unless @user.errors.of_kind?(:email_address, :deactivated)

      @user.errors.delete(:email_address, :deactivated)
      @user.errors.add(:email_address, :deactivated, message: "belongs to a closed account. Log in with it to reactivate the account")
    end
end

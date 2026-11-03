class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  # bin/e2e-server raises the limit, since a Playwright run logs in many times.
  rate_limit to: Integer(ENV.fetch("LOGIN_RATE_LIMIT", 10)), within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
  end

  def create
    user = User.authenticate_by(params.permit(:email_address, :password))
    if user&.deactivated?
      # Only said after the right password, so the form never reveals which accounts exist.
      redirect_to new_session_path, alert: "This account is deactivated. Use “Forgot password?” to reset your password and reactivate it."
    elsif user
      start_new_session_for user
      merge_visitor_cart_into(user)
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: "Try another email address or password."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end

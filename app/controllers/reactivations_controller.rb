# Coming back to a closed (deactivated) account. Logging in with the right
# password sends the person here (SessionsController#create), which proves it's
# them. They keep their email or type a new one, then reactivate.
class ReactivationsController < ApplicationController
  # How long after logging in the offer lasts.
  TIME_LIMIT = 10.minutes

  allow_unauthenticated_access
  before_action :set_user

  def show
  end

  def create
    email = params[:email_address].to_s.strip
    if email.empty?
      @user.errors.add(:email_address, :blank)
      render :show, status: :unprocessable_entity
    elsif @user.reactivate(email: email)
      session.delete(:reactivation)
      start_new_session_for @user
      merge_visitor_cart_into(@user)
      redirect_to root_path, notice: "Welcome back, #{@user.first_name}! Your account is active again."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private
    def set_user
      offer = session[:reactivation]
      expires_at = Time.zone.parse(offer["expires_at"].to_s) if offer
      @user = User.deactivated.find_by(id: offer["user_id"]) if expires_at&.future?
      return if @user

      session.delete(:reactivation)
      redirect_to new_session_path, alert: "Log in to reactivate your account."
    end
end

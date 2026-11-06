# My account: the signed-in user's details, and closing the account. The
# password has its own page (AccountPasswordsController); addresses are on
# My addresses (AddressesController).
class AccountsController < ApplicationController
  before_action :set_user

  def show
  end

  def edit
  end

  # A new email needs the current password; a name change doesn't.
  def update
    @user.assign_attributes(account_params)
    if @user.email_address_changed? && !@user.authenticate(params[:current_password].to_s)
      @user.errors.add(:current_password, "is incorrect")
      render :edit, status: :unprocessable_entity
    elsif @user.save
      redirect_to account_path, notice: "Your details are updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Closing is a soft delete (User#deactivate!): orders and reviews are kept,
  # and logging in again offers to reactivate. Admins can't close their own
  # account here, so the store is never left without its admins by accident.
  def destroy
    if @user.admin?
      redirect_to account_path, alert: "Admin accounts can't be closed here."
    elsif @user.authenticate(params[:current_password].to_s)
      terminate_session
      @user.deactivate!
      redirect_to root_path, notice: "Your account is closed. Log in again any time to reactivate it."
    else
      redirect_to account_path, alert: "Current password is incorrect, so your account is still open."
    end
  end

  private
    def set_user
      @user = Current.user
    end

    def account_params
      params.expect(user: [ :first_name, :last_name, :email_address ])
    end
end

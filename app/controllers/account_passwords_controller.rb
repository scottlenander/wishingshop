# Change password, from My account. Needs the current password; other devices
# are logged out, this one stays logged in.
class AccountPasswordsController < ApplicationController
  before_action :set_user

  def edit
  end

  def update
    new_password = params.dig(:user, :password).to_s
    if !@user.authenticate(params[:current_password].to_s)
      @user.errors.add(:current_password, "is incorrect")
    elsif new_password.empty?
      # A blank password is silently ignored by has_secure_password, so say so.
      @user.errors.add(:password, :blank)
    elsif @user.update(password: new_password, password_confirmation: params.dig(:user, :password_confirmation).to_s)
      @user.sessions.where.not(id: Current.session.id).destroy_all
      return redirect_to account_path, notice: "Password changed."
    end
    render :edit, status: :unprocessable_entity
  end

  private
    def set_user
      @user = Current.user
    end
end

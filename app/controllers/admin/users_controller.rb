# Admins manage standard users here. Admin accounts (including your own) are
# out of reach: every lookup goes through User.standard, so they 404.
# Users are never deleted: Deactivate keeps their orders and reviews, and
# Restore (or the user resetting their password) undoes it.
class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: %i[ edit update destroy restore ]

  def index
    @users = User.standard.active.order(:last_name, :first_name)
    @deactivated_users = User.standard.deactivated.order(deactivated_at: :desc)
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to admin_users_path, notice: "User created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to admin_users_path, notice: "User updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user.deactivate!
    redirect_to admin_users_path, notice: "#{@user.email_address} deactivated. Their orders and reviews are kept."
  end

  def restore
    @user.reactivate!
    redirect_to admin_users_path, notice: "#{@user.email_address} restored."
  end

  private
    def set_user
      @user = User.standard.find(params[:id])
    end

    # Leaving both password fields blank on edit keeps the current password.
    def user_params
      permitted = params.expect(user: [ :first_name, :last_name, :email_address, :password, :password_confirmation ])
      if action_name == "update" && permitted[:password].blank? && permitted[:password_confirmation].blank?
        permitted.except(:password, :password_confirmation)
      else
        permitted
      end
    end
end

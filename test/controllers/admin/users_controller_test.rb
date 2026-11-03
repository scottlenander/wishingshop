require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "visitors are sent to sign in" do
    get admin_users_path
    assert_redirected_to new_session_path
  end

  test "standard users are turned away" do
    sign_in_as @user
    get admin_users_path
    assert_redirected_to root_path
    assert_no_difference("User.count") { delete admin_user_path(users(:two)) }
  end

  test "index lists standard users only" do
    sign_in_as users(:admin)
    get admin_users_path
    assert_response :success
    assert_select "td", text: "one@example.com"
    assert_select "td", text: "admin@example.com", count: 0
  end

  test "creates a user" do
    sign_in_as users(:admin)
    assert_difference("User.count", 1) do
      post admin_users_path, params: { user: { first_name: "Nia", last_name: "New", email_address: "new@example.com", password: "secret123", password_confirmation: "secret123" } }
    end
    assert_redirected_to admin_users_path
    assert_not User.find_by(email_address: "new@example.com").admin?
  end

  test "rejects a duplicate email" do
    sign_in_as users(:admin)
    assert_no_difference("User.count") do
      post admin_users_path, params: { user: { first_name: "Tom", last_name: "Twin", email_address: "two@example.com", password: "secret123", password_confirmation: "secret123" } }
    end
    assert_response :unprocessable_entity
  end

  test "updating with a blank password keeps the old one" do
    sign_in_as users(:admin)
    patch admin_user_path(@user), params: { user: { email_address: "renamed@example.com", password: "", password_confirmation: "" } }
    assert_redirected_to admin_users_path
    @user.reload
    assert_equal "renamed@example.com", @user.email_address
    assert @user.authenticate("password")
  end

  test "updates the password" do
    sign_in_as users(:admin)
    patch admin_user_path(@user), params: { user: { email_address: @user.email_address, password: "newpass123", password_confirmation: "newpass123" } }
    assert @user.reload.authenticate("newpass123")
  end

  test "admins can't be managed here" do
    sign_in_as users(:admin)
    get edit_admin_user_path(users(:admin))
    assert_response :not_found
  end

  test "deactivating keeps the user, their orders and reviews, and logs them out" do
    sign_in_as @user
    sign_in_as users(:admin)

    assert_no_difference -> { User.count } do
      assert_no_difference -> { @user.orders.count } do
        assert_no_difference -> { @user.reviews.count } do
          delete admin_user_path(@user)
        end
      end
    end

    assert_redirected_to admin_users_path
    assert @user.reload.deactivated?
    assert_empty @user.sessions
  end

  test "deactivated users are listed separately with Restore" do
    users(:two).deactivate!
    sign_in_as users(:admin)
    get admin_users_path

    assert_select ".admin-users__deactivated td", text: "two@example.com"
    assert_select ".admin-users__deactivated button", text: "Restore"
    assert_select "table:not(.admin-users__deactivated) td", text: "two@example.com", count: 0
  end

  test "restores a deactivated user" do
    @user.deactivate!
    sign_in_as users(:admin)
    patch restore_admin_user_path(@user)

    assert_redirected_to admin_users_path
    assert_not @user.reload.deactivated?
  end

  test "a deactivated user's email can't be used for a new user" do
    users(:two).deactivate!
    sign_in_as users(:admin)
    assert_no_difference("User.count") do
      post admin_users_path, params: { user: { first_name: "Tom", last_name: "Twin", email_address: "two@example.com", password: "secret123", password_confirmation: "secret123" } }
    end

    assert_response :unprocessable_entity
    assert_select "p.error", text: "Email address belongs to a deactivated user. Restore them from the Users page instead"
  end

  test "standard users can't restore" do
    users(:two).deactivate!
    sign_in_as @user
    patch restore_admin_user_path(users(:two))
    assert users(:two).reload.deactivated?
  end

  test "first and last name are required" do
    sign_in_as users(:admin)
    assert_no_difference("User.count") do
      post admin_users_path, params: { user: { first_name: "", last_name: "", email_address: "nameless@example.com", password: "secret123", password_confirmation: "secret123" } }
    end
    assert_response :unprocessable_entity
    assert_select "p.error", text: "First name can't be blank"
  end

  test "index shows names" do
    sign_in_as users(:admin)
    get admin_users_path
    assert_select "td", text: "Olive One"
  end
end

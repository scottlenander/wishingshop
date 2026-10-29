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
      post admin_users_path, params: { user: { email_address: "new@example.com", password: "secret123", password_confirmation: "secret123" } }
    end
    assert_redirected_to admin_users_path
    assert_not User.find_by(email_address: "new@example.com").admin?
  end

  test "rejects a duplicate email" do
    sign_in_as users(:admin)
    assert_no_difference("User.count") do
      post admin_users_path, params: { user: { email_address: "two@example.com", password: "secret123", password_confirmation: "secret123" } }
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

  test "deletes a user" do
    sign_in_as users(:admin)
    assert_difference("User.count", -1) { delete admin_user_path(@user) }
    assert_redirected_to admin_users_path
  end
end

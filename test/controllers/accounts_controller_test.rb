require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:one) }

  test "visitors are sent to log in" do
    get account_path
    assert_redirected_to new_session_path
  end

  test "My account shows the details and links" do
    sign_in_as @user
    get account_path

    assert_select "dd", text: "Olive One"
    assert_select "dd", text: "one@example.com"
    assert_select "a[href=?]", addresses_path, text: "My addresses"
    assert_select "a[href=?]", edit_account_password_path, text: "Change password"
    assert_select "form[action=?] button.btn--danger", account_path, text: "Close my account"
  end

  test "the nav greeting links to My account" do
    sign_in_as @user
    get root_path
    assert_select "a.layouts-application__greeting[href=?][aria-label=?]", account_path, "Hi, Olive! My account", text: "Hi, Olive!"
  end

  test "a name change needs no password" do
    sign_in_as @user
    patch account_path, params: { user: { first_name: "Olivia", last_name: "One", email_address: "one@example.com" } }

    assert_redirected_to account_path
    assert_equal "Olivia", @user.reload.first_name
  end

  test "an email change needs the current password" do
    sign_in_as @user
    patch account_path, params: { user: { first_name: "Olive", last_name: "One", email_address: "olive@example.com" }, current_password: "wrong" }
    assert_response :unprocessable_entity
    assert_select "p.error", text: "Current password is incorrect"
    assert_equal "one@example.com", @user.reload.email_address

    patch account_path, params: { user: { first_name: "Olive", last_name: "One", email_address: "olive@example.com" }, current_password: "password" }
    assert_redirected_to account_path
    assert_equal "olive@example.com", @user.reload.email_address
  end

  test "a taken email is refused" do
    sign_in_as @user
    patch account_path, params: { user: { first_name: "Olive", last_name: "One", email_address: "two@example.com" }, current_password: "password" }
    assert_select "p.error", text: "Email address has already been taken"
  end

  test "closing needs the current password" do
    sign_in_as @user
    delete account_path, params: { current_password: "wrong" }

    assert_redirected_to account_path
    assert_not @user.reload.deactivated?
  end

  test "closing deactivates the account and logs out" do
    sign_in_as @user
    assert_no_difference("User.count") { delete account_path, params: { current_password: "password" } }

    assert_redirected_to root_path
    assert_equal "Your account is closed. Log in again any time to reactivate it.", flash[:notice]
    assert @user.reload.deactivated?
    assert_empty @user.sessions
    get account_path
    assert_redirected_to new_session_path
  end

  test "admins can't close their own account here" do
    sign_in_as users(:admin)
    delete account_path, params: { current_password: "password" }
    assert_not users(:admin).reload.deactivated?
  end
end

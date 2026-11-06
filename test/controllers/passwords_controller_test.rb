require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new" do
    get new_password_path
    assert_response :success
  end

  test "create" do
    post passwords_path, params: { email_address: @user.email_address }
    assert_enqueued_email_with PasswordsMailer, :reset, args: [ @user ]
    assert_redirected_to new_session_path

    follow_redirect!
    assert_notice "reset instructions sent"
  end

  test "create for an unknown user redirects but sends no mail" do
    post passwords_path, params: { email_address: "missing-user@example.com" }
    assert_enqueued_emails 0
    assert_redirected_to new_session_path

    follow_redirect!
    assert_notice "reset instructions sent"
  end

  test "edit" do
    get edit_password_path(@user.password_reset_token)
    assert_response :success
  end

  test "edit with invalid password reset token" do
    get edit_password_path("invalid token")
    assert_redirected_to new_password_path

    follow_redirect!
    assert_notice "reset link is invalid"
  end

  test "update" do
    assert_changes -> { @user.reload.password_digest } do
      put password_path(@user.password_reset_token), params: { password: "newpass123", password_confirmation: "newpass123" }
      assert_redirected_to new_session_path
    end

    follow_redirect!
    assert_notice "Password has been reset"
  end

  test "resetting the password reactivates a deactivated user" do
    @user.deactivate!
    put password_path(@user.password_reset_token), params: { password: "newpass123", password_confirmation: "newpass123" }

    assert_not @user.reload.deactivated?
    follow_redirect!
    assert_notice "your account is active again"

    post session_path, params: { email_address: @user.email_address, password: "newpass123" }
    assert cookies[:session_id].present?
  end

  test "a failed reset leaves the user deactivated" do
    @user.deactivate!
    put password_path(@user.password_reset_token), params: { password: "no", password_confirmation: "match" }
    assert @user.reload.deactivated?
  end

  test "deactivated users can request a reset" do
    @user.deactivate!
    post passwords_path, params: { email_address: @user.email_address }
    assert_enqueued_email_with PasswordsMailer, :reset, args: [ @user ]
  end

  test "a too-short new password says why" do
    token = @user.password_reset_token
    put password_path(token), params: { password: "short", password_confirmation: "short" }
    assert_redirected_to edit_password_path(token)
    assert_equal "Password is too short (minimum is 8 characters)", flash[:alert]
  end

  test "update with non matching passwords" do
    token = @user.password_reset_token
    assert_no_changes -> { @user.reload.password_digest } do
      put password_path(token), params: { password: "no", password_confirmation: "match" }
      assert_redirected_to edit_password_path(token)
    end

    follow_redirect!
    assert_notice "Passwords did not match"
  end

  private
    def assert_notice(text)
      assert_select "div", /#{text}/
    end
end

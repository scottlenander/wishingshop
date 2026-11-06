require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new" do
    get new_session_path
    assert_response :success
  end

  test "create with valid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "create with invalid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "wrong" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "a deactivated user with the right password is offered reactivation, not logged in" do
    @user.deactivate!
    post session_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to reactivation_path
    assert_nil cookies[:session_id]
  end

  test "a deactivated user with the wrong password gets the usual error" do
    @user.deactivate!
    post session_path, params: { email_address: @user.email_address, password: "wrong" }

    assert_equal "Try another email address or password.", flash[:alert]
  end

  test "destroy" do
    sign_in_as(User.take)

    delete session_path

    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end
end

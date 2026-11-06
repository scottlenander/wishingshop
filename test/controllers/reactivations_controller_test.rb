require "test_helper"

class ReactivationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @user.deactivate!
  end

  def log_in_closed_account
    post session_path, params: { email_address: @user.email_address, password: "password" }
    follow_redirect!
  end

  test "without logging in first, it asks to log in" do
    get reactivation_path
    assert_redirected_to new_session_path
    assert_equal "Log in to reactivate your account.", flash[:alert]
  end

  test "logging in to a closed account shows the offer with the email filled in" do
    log_in_closed_account

    assert_select "h1", text: "Reactivate your account"
    assert_select "input[name=email_address][value='one@example.com']"
  end

  test "keeping the email reactivates and logs in" do
    log_in_closed_account
    post reactivation_path, params: { email_address: "one@example.com" }

    assert_redirected_to root_path
    assert_equal "Welcome back, Olive! Your account is active again.", flash[:notice]
    assert_not @user.reload.deactivated?
    assert cookies[:session_id].present?
  end

  test "a new email reactivates under that email, freeing the old one" do
    log_in_closed_account
    post reactivation_path, params: { email_address: "Olive.New@Example.com" }

    assert_equal "olive.new@example.com", @user.reload.email_address
    assert_not @user.deactivated?
    get reactivation_path
    assert_redirected_to new_session_path, "the offer is used up"
  end

  test "a taken or blank email shows the page again" do
    log_in_closed_account
    post reactivation_path, params: { email_address: "two@example.com" }
    assert_response :unprocessable_entity
    assert_select "p.error", text: "Email address has already been taken"
    assert_select "input[name=email_address][value='two@example.com']"

    post reactivation_path, params: { email_address: " " }
    assert_select "p.error", text: "Email address can't be blank"
    assert @user.reload.deactivated?
  end

  test "the offer runs out after 10 minutes" do
    log_in_closed_account
    travel 11.minutes do
      post reactivation_path, params: { email_address: "one@example.com" }
      assert_redirected_to new_session_path
    end
    assert @user.reload.deactivated?
  end
end

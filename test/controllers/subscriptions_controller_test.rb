require "test_helper"

class SubscriptionsControllerTest < ActionDispatch::IntegrationTest
  test "visitors are sent to sign in" do
    get subscriptions_path
    assert_redirected_to new_session_path
  end

  test "lists my subscriptions" do
    sign_in_as users(:one)

    get subscriptions_path
    assert_response :success
    assert_select "td", text: "Hoodie"
  end

  test "removes my subscription" do
    sign_in_as users(:one)

    assert_difference("Subscriber.count", -1) { delete subscription_path(subscribers(:one_hoodie)) }
  end

  test "can't remove someone else's subscription" do
    sign_in_as users(:two)

    assert_no_difference("Subscriber.count") { delete subscription_path(subscribers(:one_hoodie)) }
    assert_response :not_found
  end
end

require "test_helper"

class UnsubscribesControllerTest < ActionDispatch::IntegrationTest
  test "a valid token removes the subscriber" do
    subscriber = subscribers(:david)
    token = subscriber.generate_token_for(:unsubscribe)

    assert_difference("Subscriber.count", -1) { get unsubscribe_path(token: token) }
    assert_redirected_to root_path
  end
end

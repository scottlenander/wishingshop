require "test_helper"

class SubscribersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @product = products(:hoodie)
  end

  test "a visitor subscribes with an email" do
    assert_difference("Subscriber.count", 1) do
      post product_subscribers_path(@product), params: { subscriber: { email: "visitor@example.com" } }
    end
    assert_redirected_to product_path(@product)
    assert_nil @product.subscribers.find_by(email: "visitor@example.com").user
  end

  test "a signed-in user subscribes with one click using their account email" do
    sign_in_as users(:two)

    assert_difference("Subscriber.count", 1) { post product_subscribers_path(@product) }
    subscriber = @product.subscribers.find_by(user: users(:two))
    assert_equal "two@example.com", subscriber.email
  end

  test "subscribing again doesn't duplicate" do
    sign_in_as users(:one)

    assert_no_difference("Subscriber.count") { post product_subscribers_path(@product) }
    assert_equal "You are now subscribed.", flash[:notice]
  end

  test "a signed-in user claims an earlier visitor sign-up with their email" do
    visitor_signup = @product.subscribers.create!(email: "two@example.com")
    sign_in_as users(:two)

    assert_no_difference("Subscriber.count") { post product_subscribers_path(@product) }
    assert_equal users(:two), visitor_signup.reload.user
  end
end

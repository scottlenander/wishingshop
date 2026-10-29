require "test_helper"

class Admin::SubscribersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @subscriber = subscribers(:david)
    @product = products(:tshirt)
  end

  test "standard users are turned away" do
    sign_in_as users(:one)
    get admin_subscribers_path
    assert_redirected_to root_path
    assert_no_difference("Subscriber.count") { delete admin_subscriber_path(@subscriber) }
  end

  test "lists subscribers by product" do
    sign_in_as users(:admin)
    get admin_subscribers_path
    assert_response :success
    assert_select "h2", text: /T-Shirt/
    assert_select "td", text: "david@example.org"
  end

  test "adds a subscriber" do
    sign_in_as users(:admin)
    assert_difference("Subscriber.count", 1) do
      post admin_subscribers_path, params: { subscriber: { email: "New@Example.com ", product_id: @product.id } }
    end
    assert_redirected_to admin_subscribers_path
    assert @product.subscribers.exists?(email: "new@example.com")
  end

  test "rejects a duplicate email on the same product" do
    sign_in_as users(:admin)
    assert_no_difference("Subscriber.count") do
      post admin_subscribers_path, params: { subscriber: { email: "chris@example.org", product_id: @product.id } }
    end
    assert_response :unprocessable_entity
  end

  test "edits email and moves to another product" do
    other = Product.create!(name: "Socks", inventory_count: 0)
    sign_in_as users(:admin)
    patch admin_subscriber_path(@subscriber), params: { subscriber: { email: "dave@example.org", product_id: other.id } }
    assert_redirected_to admin_subscribers_path
    @subscriber.reload
    assert_equal "dave@example.org", @subscriber.email
    assert_equal other, @subscriber.product
  end

  test "removes a subscriber" do
    sign_in_as users(:admin)
    assert_difference("Subscriber.count", -1) { delete admin_subscriber_path(@subscriber) }
  end
end

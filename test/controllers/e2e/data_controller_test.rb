require "test_helper"

class E2e::DataControllerTest < ActionDispatch::IntegrationTest
  setup do
    ENV["E2E"] = "1"
    @user = users(:one)
    @user.addresses.create!(kind: :billing, name: "Olive One", line1: "1 Main St", city: "Springfield", state: "IL", postal_code: "62701")
  end

  teardown { ENV.delete("E2E") }

  test "every route is a 404 unless E2E=1" do
    ENV.delete("E2E")

    post e2e_users_reset_path, params: { email: @user.email_address }
    assert_response :not_found
    post e2e_products_stock_path, params: { sku: "T-SHIRT", inventory_count: 3 }
    assert_response :not_found
    post e2e_announcements_delete_path, params: { title_prefix: "Big" }
    assert_response :not_found
    post e2e_featured_products_delete_path, params: { sku: "HOODIE" }
    assert_response :not_found

    assert_equal 15, products(:tshirt).reload.inventory_count
    assert @user.cart.cart_items.any?
  end

  test "reset_user clears the user's cart, addresses, subscriptions and reviews" do
    post e2e_users_reset_path, params: { email: @user.email_address }, as: :json

    assert_response :no_content
    assert_empty @user.cart.cart_items
    assert_empty @user.addresses.reload
    assert_empty Subscriber.where(email: @user.email_address)
    assert_empty @user.reviews
    assert Subscriber.exists?(email: "david@example.org"), "other people's subscriptions stay"
  end

  test "reset_user can clear only some parts" do
    post e2e_users_reset_path, params: { email: @user.email_address, only: %w[ cart ] }, as: :json

    assert_response :no_content
    assert_empty @user.cart.cart_items
    assert @user.addresses.reload.any?
    assert @user.reviews.any?
  end

  test "reset_user refuses unknown parts and unknown users" do
    post e2e_users_reset_path, params: { email: @user.email_address, only: %w[ orders ] }, as: :json
    assert_response :bad_request
    assert @user.cart.cart_items.any?

    post e2e_users_reset_path, params: { email: "nobody@example.com" }, as: :json
    assert_response :not_found
  end

  test "set_stock updates the product and emails its subscriber on a restock" do
    assert_enqueued_emails 1 do
      post e2e_products_stock_path, params: { sku: "HOODIE", inventory_count: 5 }, as: :json
    end

    assert_response :no_content
    assert_equal 5, products(:hoodie).reload.inventory_count
  end

  test "delete_announcements only removes titles with the prefix" do
    post e2e_announcements_delete_path, params: { title_prefix: "Big" }, as: :json

    assert_response :no_content
    assert_not Announcement.exists?(title: "Big T-Shirt sale")
    assert Announcement.exists?(title: "Free shipping")
  end

  test "delete_announcements treats % in the prefix as text" do
    count = Announcement.count
    post e2e_announcements_delete_path, params: { title_prefix: "%" }, as: :json

    assert_response :no_content
    assert_equal count, Announcement.count
  end

  test "delete_featured_products removes that product's picks" do
    post e2e_featured_products_delete_path, params: { sku: "HOODIE" }, as: :json

    assert_response :no_content
    assert_empty products(:hoodie).featured_products
  end
end

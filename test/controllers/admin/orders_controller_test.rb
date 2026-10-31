require "test_helper"

class Admin::OrdersControllerTest < ActionDispatch::IntegrationTest
  test "standard users are turned away" do
    sign_in_as users(:one)
    get admin_orders_path
    assert_redirected_to root_path
  end

  test "admins see every order" do
    sign_in_as users(:admin)
    get admin_orders_path
    assert_response :success
    assert_select "td", text: "one@example.com"
    assert_select "td", text: "two@example.com"
  end
end

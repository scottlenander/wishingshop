require "test_helper"

class CheckoutsControllerTest < ActionDispatch::IntegrationTest
  VALID = {
    bill_name: "Olive One", bill_line1: "1 Main St", bill_city: "Springfield", bill_state: "IL",
    bill_postal_code: "62701", shipping_method: "same_day",
    card_name: "Olive One", card_number: "4242 4242 4242 4242", card_expiry: "12/40", card_cvc: "123"
  }.freeze

  test "a visitor is sent to log in, then back to checkout with their cart merged" do
    post cart_items_path, params: { product_id: products(:tshirt).id, quantity: 1 }

    get checkout_path
    assert_redirected_to new_session_path

    post session_path, params: { email_address: "two@example.com", password: "password" }
    assert_redirected_to checkout_url
    assert_equal 1, users(:two).reload.cart.cart_items.sum(:quantity)

    follow_redirect!
    assert_response :success
    assert_select ".checkout__items li", text: /1 × T-Shirt/
  end

  test "an empty cart goes back to the cart" do
    sign_in_as users(:two)
    get checkout_path
    assert_redirected_to cart_path
  end

  test "shows the form pre-filled with the user's name and shipping prices" do
    sign_in_as users(:one)
    get checkout_path
    assert_response :success
    assert_select "input[name='checkout[bill_name]'][value='Olive One']"
    assert_select "input[type=checkbox][name='checkout[same_as_billing]'][checked]"
    assert_select "label", text: /Save as my billing address/
    assert_select ".checkout__method", text: /Two-day.*\$9\.99/m
    assert_select ".checkout__total", text: "$44.97"
  end

  test "places the order and shows it" do
    sign_in_as users(:one)

    assert_difference("Order.count", 1) { post checkout_path, params: { checkout: VALID } }
    order = Order.order(:created_at).last
    assert_redirected_to order_path(order)
    assert_equal "Thanks! Your order #{order.number} is placed.", flash[:notice]
    assert_equal 1999 * 2 + 1999, order.total_cents
  end

  test "errors show the form again with everything kept, so only the wrong field needs fixing" do
    sign_in_as users(:one)

    post checkout_path, params: { checkout: VALID.merge(card_expiry: "13/40") }
    assert_response :unprocessable_entity
    assert_select ".checkout__errors li", text: "Expiry (MM/YY) must look like MM/YY"
    assert_select "input[name='checkout[card_number]'][value='4242 4242 4242 4242']"
    assert_select "input[name='checkout[card_expiry]'][value='13/40']"
    assert_select "input[name='checkout[card_cvc]'][value='123']"
    assert_select "input[name='checkout[bill_line1]'][value='1 Main St']"
    # Only the wrong field is marked.
    assert_select ".field_with_errors input[name='checkout[card_expiry]']"
    assert_select ".field_with_errors input[name='checkout[card_number]']", count: 0
  end

  test "a declined card keeps the card details" do
    sign_in_as users(:one)

    post checkout_path, params: { checkout: VALID.merge(card_number: "4000 0000 0000 0002") }
    assert_select ".checkout__errors li", text: /declined/
    assert_select "input[name='checkout[card_number]'][value='4000 0000 0000 0002']"
  end

  test "the expiry field formats itself" do
    sign_in_as users(:one)
    get checkout_path
    assert_select "input[name='checkout[card_expiry]'][data-controller='card-expiry'][maxlength='5']"
  end

  test "card details are filtered from logs" do
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    filtered = filter.filter("checkout" => { "card_number" => "4242", "card_cvc" => "123", "card_expiry" => "12/40" })
    assert_equal %w[ [FILTERED] ] * 3, filtered["checkout"].values
  end

  test "fills in the saved billing address and lists saved shipping addresses" do
    user = users(:one)
    user.addresses.create!(kind: :billing, name: "Olive One", line1: "7 Saved Ave", city: "Peoria", state: "IL", postal_code: "61602")
    user.addresses.create!(kind: :shipping, nickname: "Cabin", name: "Olive One", line1: "5 Lake Rd", city: "Duluth", state: "MN", postal_code: "55802")
    sign_in_as user

    get checkout_path
    assert_select "input[name='checkout[bill_line1]'][value='7 Saved Ave']"
    assert_select "label", text: /Update my saved billing address/
    assert_select ".checkout__shipping--choices .checkout__method", text: /Cabin/
    assert_select ".checkout__choice-new", text: /New address/
  end

  test "saves a new shipping address from checkout" do
    sign_in_as users(:one)
    params = VALID.merge(same_as_billing: "0", shipping_choice: "new", ship_name: "Olive One", ship_line1: "9 Office Rd",
                         ship_city: "Chicago", ship_state: "IL", ship_postal_code: "60601", save_shipping: "1", shipping_nickname: "Work")

    assert_difference("Address.count", 1) { post checkout_path, params: { checkout: params } }
    order = Order.order(:created_at).last
    assert_equal "9 Office Rd", order.ship_line1
    assert_equal "1 Main St", order.bill_line1
  end
end

require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  NEW_USER = { first_name: "Ann", last_name: "New", email_address: "ann@example.com",
               password: "secret123", password_confirmation: "secret123" }.freeze

  test "the sign-up page" do
    get new_registration_path
    assert_response :success
    assert_select "form[action=?]", registration_path
    assert_select "input[name='user[password]'][minlength='8'][autocomplete='new-password']"
    assert_select "a[href=?]", new_session_path, text: "Log in"
  end

  test "signing up logs in and offers the optional billing step" do
    assert_difference("User.count", 1) { post registration_path, params: { user: NEW_USER } }

    user = User.find_by!(email_address: "ann@example.com")
    assert_redirected_to new_address_path(kind: "billing", welcome: 1)
    assert_equal "Welcome to WishingShop, Ann!", flash[:notice]
    assert cookies[:session_id].present?
    assert_not user.admin?

    follow_redirect!
    assert_select "h1", text: "Add your billing address (optional)"
    assert_select "a[href=?]", root_path, text: "Skip for now"
  end

  test "sign-up can't make an admin" do
    post registration_path, params: { user: NEW_USER.merge(admin: true) }
    assert_not User.find_by!(email_address: "ann@example.com").admin?
  end

  test "the visitor's cart is kept, and a checkout visit comes back to checkout" do
    post cart_items_path, params: { product_id: products(:tshirt).id, quantity: 2 }
    get checkout_path # asks to log in, remembering checkout
    post registration_path, params: { user: NEW_USER }

    assert_redirected_to checkout_url
    assert_equal 2, User.find_by!(email_address: "ann@example.com").cart.cart_items.sum(:quantity)
  end

  test "errors show the form again, keeping what was typed except passwords" do
    post registration_path, params: { user: NEW_USER.merge(password: "short", password_confirmation: "short") }

    assert_response :unprocessable_entity
    assert_select "p.error", text: "Password is too short (minimum is 8 characters)"
    assert_select "input[name='user[email_address]'][value='ann@example.com']"
    assert_select "input[name='user[password]']:not([value])"
  end

  test "an email in use is refused" do
    post registration_path, params: { user: NEW_USER.merge(email_address: "two@example.com") }
    assert_select "p.error", text: "Email address has already been taken"
  end

  test "a closed account's email points to logging in" do
    users(:two).deactivate!
    post registration_path, params: { user: NEW_USER.merge(email_address: "two@example.com") }
    assert_select "p.error", text: "Email address belongs to a closed account. Log in with it to reactivate the account"
  end

  test "signed-in users go to My account" do
    sign_in_as users(:one)
    get new_registration_path
    assert_redirected_to account_path
  end
end

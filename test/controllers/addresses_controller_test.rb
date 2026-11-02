require "test_helper"

class AddressesControllerTest < ActionDispatch::IntegrationTest
  FIELDS = { name: "Olive One", line1: "1 Main St", city: "Springfield", state: "IL", postal_code: "62701" }.freeze

  setup { sign_in_as users(:one) }

  test "visitors are sent to sign in" do
    sign_out
    get addresses_path
    assert_redirected_to new_session_path
  end

  test "lists addresses, with a prompt when there's no billing address" do
    get addresses_path
    assert_response :success
    assert_select "p", text: /No billing address saved/
  end

  test "adds a billing and a shipping address" do
    assert_difference("Address.count", 2) do
      post addresses_path, params: { address: FIELDS.merge(kind: "billing") }
      post addresses_path, params: { address: FIELDS.merge(kind: "shipping", nickname: "Work") }
    end
    assert_redirected_to addresses_path

    get addresses_path
    assert_select ".addresses__nickname", text: "Work"
    assert_select "address", text: /1 Main St/, count: 2
  end

  test "a second billing address goes to editing the first" do
    billing = users(:one).addresses.create!(FIELDS.merge(kind: :billing))
    get new_address_path(kind: "billing")
    assert_redirected_to edit_address_path(billing)
  end

  test "edits and deletes" do
    address = users(:one).addresses.create!(FIELDS.merge(kind: :shipping, nickname: "Home"))

    patch address_path(address), params: { address: { line1: "2 Elm St", kind: "billing" } }
    address.reload
    assert_equal "2 Elm St", address.line1
    assert address.shipping?, "kind can't be changed"

    assert_difference("Address.count", -1) { delete address_path(address) }
  end

  test "shows errors" do
    post addresses_path, params: { address: FIELDS.merge(kind: "shipping", postal_code: "nope") }
    assert_response :unprocessable_entity
    assert_select "p.error", text: /ZIP code/
  end

  test "someone else's address is not found" do
    other = users(:two).addresses.create!(FIELDS.merge(kind: :shipping, nickname: "Home"))
    get edit_address_path(other)
    assert_response :not_found
    assert_no_difference("Address.count") { delete address_path(other) }
  end
end

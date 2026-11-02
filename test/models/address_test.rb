require "test_helper"

class AddressTest < ActiveSupport::TestCase
  def address(**overrides)
    users(:one).addresses.new({ kind: :shipping, nickname: "Home", name: " Olive  One ", line1: "1 Main St",
                                city: "Springfield", state: "il", postal_code: "62701" }.merge(overrides))
  end

  test "valid and tidied" do
    a = address
    assert a.valid?
    assert_equal "Olive One", a.name
    assert_equal "IL", a.state
    assert_equal [ "Olive One", "1 Main St", "Springfield, IL 62701" ], a.lines
  end

  test "validates the address" do
    a = address(line1: "", state: "Illinois", postal_code: "123")
    assert_not a.valid?
    assert_includes a.errors.full_messages, "Address can't be blank"
    assert_includes a.errors.full_messages, "State must be a 2-letter state code, like NY"
    assert_includes a.errors.full_messages, "ZIP code must be a ZIP code like 12345"
  end

  test "shipping addresses need a nickname, unique per user" do
    assert_not address(nickname: "").valid?
    address.save!
    assert_not address.valid?
    assert users(:two).addresses.new(address.attributes.except("id", "user_id")).valid?
  end

  test "only one billing address per user, and it needs no nickname" do
    billing = address(kind: :billing, nickname: nil)
    assert billing.valid?
    billing.save!
    assert_not address(kind: :billing, nickname: nil).valid?
    assert_equal billing, users(:one).reload.billing_address
  end
end

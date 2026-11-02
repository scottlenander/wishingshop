require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "standard scope excludes admins" do
    assert_includes User.standard, users(:one)
    assert_not_includes User.standard, users(:admin)
  end

  test "changing email updates the user's subscriptions" do
    user = users(:one)
    user.update!(email_address: "new-one@example.com")

    assert_equal "new-one@example.com", subscribers(:one_hoodie).reload.email
    assert_equal "david@example.org", subscribers(:david).reload.email
  end

  test "first and last name are required and tidied" do
    user = User.new(email_address: "x@example.com", password: "secret123", first_name: "  Ann  ", last_name: " van  Dyke ")
    assert user.valid?
    assert_equal "Ann", user.first_name
    assert_equal "Ann van Dyke", user.full_name

    user.first_name = ""
    assert_not user.valid?
    assert_includes user.errors[:first_name], "can't be blank"
  end
end

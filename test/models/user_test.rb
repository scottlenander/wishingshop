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
end

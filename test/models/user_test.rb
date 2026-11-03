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

  test "deactivate! keeps the user and ends their sessions; reactivate! undoes it" do
    user = users(:one)
    user.sessions.create!

    user.deactivate!
    assert user.deactivated?
    assert_empty user.sessions.reload
    assert_includes User.deactivated, user
    assert_not_includes User.active, user

    user.reactivate!
    assert_not user.reload.deactivated?
    assert_includes User.active, user
  end

  test "a deactivated user's email is still taken, with a pointer to Restore" do
    users(:two).deactivate!
    user = User.new(email_address: "two@example.com", password: "secret123", first_name: "Tom", last_name: "Twin")

    assert_not user.valid?
    assert_equal [ "belongs to a deactivated user. Restore them from the Users page instead" ], user.errors[:email_address]
  end

  test "an active user's email gives the usual error" do
    user = User.new(email_address: "two@example.com", password: "secret123", first_name: "Tom", last_name: "Twin")

    assert_not user.valid?
    assert_equal [ "has already been taken" ], user.errors[:email_address]
  end

  test "a deactivated user can still be saved" do
    user = users(:one)
    user.deactivate!
    assert user.update(first_name: "Olivia")
  end

  test "orders aren't deleted with a user" do
    assert_raises(ActiveRecord::DeleteRestrictionError) { users(:one).destroy }
  end
end

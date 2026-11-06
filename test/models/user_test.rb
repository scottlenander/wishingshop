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

  test "a deactivated user's email is still taken, as its own kind of error" do
    users(:two).deactivate!
    user = User.new(email_address: "two@example.com", password: "secret123", first_name: "Tom", last_name: "Twin")

    assert_not user.valid?
    assert_equal [ "belongs to a closed account" ], user.errors[:email_address]
    assert user.errors.of_kind?(:email_address, :deactivated)
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

  test "passwords need at least 8 characters" do
    user = users(:one)
    assert_not user.update(password: "short12", password_confirmation: "short12")
    assert_includes user.errors.full_messages, "Password is too short (minimum is 8 characters)"
    assert User.find(user.id).update(first_name: "Olivia"), "saving without a new password still works"
  end

  test "reactivate keeps the email, or takes a new one that its subscriptions follow" do
    user = users(:one)
    user.deactivate!
    assert user.reactivate
    assert_equal "one@example.com", user.reload.email_address

    user.deactivate!
    assert user.reactivate(email: "olive-new@example.com")
    assert_not user.reload.deactivated?
    assert_equal "olive-new@example.com", user.email_address
    assert_equal "olive-new@example.com", subscribers(:one_hoodie).reload.email
  end

  test "reactivating with a taken email fails and leaves the account closed" do
    user = users(:one)
    user.deactivate!

    assert_not user.reactivate(email: "two@example.com")
    assert_includes user.errors[:email_address], "has already been taken"
    assert user.reload.deactivated?
  end
end

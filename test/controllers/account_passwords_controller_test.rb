require "test_helper"

class AccountPasswordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_device = @user.sessions.create!
    sign_in_as @user
  end

  def change(current:, new:, confirm: new)
    patch account_password_path, params: { current_password: current, user: { password: new, password_confirmation: confirm } }
  end

  test "a wrong current password is refused" do
    change(current: "wrong", new: "newpass123")
    assert_response :unprocessable_entity
    assert_select "p.error", text: "Current password is incorrect"
    assert @user.reload.authenticate("password")
  end

  test "a blank, short or mismatched new password is refused" do
    change(current: "password", new: "")
    assert_select "p.error", text: "Password can't be blank"

    change(current: "password", new: "short")
    assert_select "p.error", text: "Password is too short (minimum is 8 characters)"

    change(current: "password", new: "newpass123", confirm: "different1")
    assert_select "p.error", text: "Password confirmation doesn't match Password"
    assert @user.reload.authenticate("password")
  end

  test "changing it logs out other devices but not this one" do
    change(current: "password", new: "newpass123")

    assert_redirected_to account_path
    assert @user.reload.authenticate("newpass123")
    assert_not Session.exists?(@other_device.id)
    get account_path
    assert_response :success
  end
end

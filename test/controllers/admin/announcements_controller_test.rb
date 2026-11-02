require "test_helper"

class Admin::AnnouncementsControllerTest < ActionDispatch::IntegrationTest
  test "standard users are turned away" do
    sign_in_as users(:one)
    get admin_announcements_path
    assert_redirected_to root_path
    assert_no_difference("Announcement.count") { post admin_announcements_path, params: { announcement: { title: "Hi" } } }
  end

  test "lists announcements with status" do
    sign_in_as users(:admin)
    get admin_announcements_path
    assert_response :success
    assert_select "tr##{ActionView::RecordIdentifier.dom_id(announcements(:scheduled))} td", text: "Scheduled"
  end

  test "creates an announcement with products" do
    sign_in_as users(:admin)
    assert_difference("Announcement.count", 1) do
      post admin_announcements_path, params: { announcement: {
        kind: "new_product", title: "New hoodie", body: "Cosy.", starts_at: 1.minute.ago, position: 3,
        product_ids: [ "", products(:hoodie).id ]
      } }
    end
    assert_redirected_to admin_announcements_path
    announcement = Announcement.find_by!(title: "New hoodie")
    assert announcement.new_product?
    assert_equal [ products(:hoodie) ], announcement.products
  end

  test "shows errors for an invalid announcement" do
    sign_in_as users(:admin)
    post admin_announcements_path, params: { announcement: { title: "" } }
    assert_response :unprocessable_entity
    assert_select "p.error"
  end

  test "updates and deletes" do
    sign_in_as users(:admin)
    patch admin_announcement_path(announcements(:news)), params: { announcement: { title: "Faster shipping" } }
    assert_equal "Faster shipping", announcements(:news).reload.title

    assert_difference("Announcement.count", -1) { delete admin_announcement_path(announcements(:news)) }
  end
end

require "test_helper"

class AnnouncementTest < ActiveSupport::TestCase
  test "live shows started, not-ended announcements by position" do
    assert_equal [ announcements(:sale), announcements(:news) ], Announcement.live.to_a
  end

  test "live includes announcements with no end date and excludes ended ones" do
    assert_includes Announcement.live, announcements(:news)
    assert_not_includes Announcement.live, announcements(:ended)
    assert_not_includes Announcement.live, announcements(:scheduled)
  end

  test "status" do
    assert_equal "Live", announcements(:sale).status
    assert_equal "Scheduled", announcements(:scheduled).status
    assert_equal "Ended", announcements(:ended).status
  end

  test "validations" do
    assert_not Announcement.new(title: "").valid?
    assert_not Announcement.new(title: "x" * 81).valid?
    assert_not Announcement.new(title: "Hi", body: "x" * 281).valid?
    assert_not Announcement.new(title: "Hi", starts_at: Time.current, ends_at: 1.day.ago).valid?
    assert_not Announcement.new(title: "Hi", kind: "party").valid?
  end

  test "starts now by default and has kind labels" do
    announcement = Announcement.new(title: "Hi")
    assert_in_delta Time.current, announcement.starts_at, 1.second
    assert_equal "News", announcement.kind_label
    assert_equal "Sale", announcements(:sale).kind_label
  end

  test "links products" do
    assert_equal [ products(:tshirt) ], announcements(:sale).products
  end
end

require "test_helper"

class Payment::CardTest < ActiveSupport::TestCase
  def card(**overrides)
    Payment::Card.new({ name: "Olive One", number: "4242 4242 4242 4242", expiry: "12/#{(Date.current.year + 2) % 100}", cvc: "123" }.merge(overrides))
  end

  test "a valid test card" do
    assert card.valid?
    assert_equal "Visa", card.brand
    assert_equal "4242", card.last4
    assert_equal "4242424242424242", card.digits
  end

  test "detects brands" do
    assert_equal "Mastercard", card(number: "5555 5555 5555 4444").brand
    assert_equal "Amex", card(number: "3782 822463 10005").brand
    assert_equal "Discover", card(number: "6011 1111 1111 1117").brand
  end

  test "number must pass the checksum" do
    assert_includes card(number: "4242 4242 4242 4241").tap(&:valid?).errors[:number], "isn't a valid card number"
    assert_includes card(number: "1234").tap(&:valid?).errors[:number], "must be 12 to 19 digits"
  end

  test "expiry must be MM/YY and not in the past" do
    assert_includes card(expiry: "13/30").tap(&:valid?).errors[:expiry], "must look like MM/YY"
    assert_includes card(expiry: "01/20").tap(&:valid?).errors[:expiry], "is in the past"

    assert card(expiry: "1240").valid?, "the slash is optional"

    this_month = Date.current.strftime("%m/%y")
    assert card(expiry: this_month).valid?, "a card is valid until the end of its expiry month"
  end

  test "cvc and name are required" do
    assert_includes card(cvc: "12").tap(&:valid?).errors[:cvc], "must be 3 or 4 digits"
    assert_includes card(name: "").tap(&:valid?).errors[:name], "can't be blank"
  end
end

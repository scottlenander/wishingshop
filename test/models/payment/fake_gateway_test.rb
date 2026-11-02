require "test_helper"

class Payment::FakeGatewayTest < ActiveSupport::TestCase
  def card(number)
    Payment::Card.new(name: "Olive One", number: number, expiry: "12/#{(Date.current.year + 2) % 100}", cvc: "123")
  end

  test "a valid card is charged and returns only brand and last 4" do
    assert_equal({ brand: "Visa", last4: "4242" }, Payment::FakeGateway.charge(card("4242424242424242"), 1999))
  end

  test "the decline test card is declined" do
    error = assert_raises(Payment::Declined) { Payment::FakeGateway.charge(card("4000 0000 0000 0002"), 1999) }
    assert_match "declined", error.message
  end
end

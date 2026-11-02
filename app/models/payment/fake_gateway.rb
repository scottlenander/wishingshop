# Stands in for a real payment provider. Valid cards are "charged" instantly;
# one test number is always declined so failures can be tested.
#
#   4242 4242 4242 4242   succeeds
#   4000 0000 0000 0002   declined
class Payment::FakeGateway
  DECLINED_NUMBER = "4000000000000002"

  def self.charge(card, amount_cents)
    raise ArgumentError, "Card details are invalid" unless card.valid?
    raise ArgumentError, "Amount must be positive" unless amount_cents.positive?
    raise Payment::Declined, "Your card was declined. Try another card." if card.digits == DECLINED_NUMBER

    { brand: card.brand, last4: card.last4 }
  end
end

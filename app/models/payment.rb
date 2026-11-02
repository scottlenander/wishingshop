# Fake card payments for this practice shop. See Payment::FakeGateway.
module Payment
  class Declined < StandardError; end
end

# Card details typed at checkout. Only lives for the request: nothing here is
# saved except the brand and last 4 digits (see Checkout#place!).
class Payment::Card
  include ActiveModel::Model
  include ActiveModel::Attributes

  BRANDS = { /\A4/ => "Visa", /\A(5[1-5]|2[2-7])/ => "Mastercard", /\A3[47]/ => "Amex", /\A6(011|5)/ => "Discover" }.freeze

  attribute :name, :string
  attribute :number, :string
  attribute :expiry, :string
  attribute :cvc, :string

  validates :name, presence: true
  validate :number_is_valid, :expiry_is_valid, :cvc_is_valid

  def digits = number.to_s.gsub(/[\s-]/, "")
  def last4 = digits.last(4)
  def brand = BRANDS.find { |pattern, _| digits.match?(pattern) }&.last || "Card"

  private
    def number_is_valid
      if !digits.match?(/\A\d{12,19}\z/)
        errors.add(:number, "must be 12 to 19 digits")
      elsif !luhn_valid?
        errors.add(:number, "isn't a valid card number")
      end
    end

    # The checksum every real card number passes.
    def luhn_valid?
      sum = digits.reverse.chars.each_with_index.sum do |char, index|
        n = char.to_i
        n *= 2 if index.odd?
        n > 9 ? n - 9 : n
      end
      (sum % 10).zero?
    end

    def expiry_is_valid
      # "12/30", "12 / 30" and "1230" all work.
      match = expiry.to_s.strip.match(%r{\A(\d{2})\s*/?\s*(\d{2})\z})
      month = match && match[1].to_i
      return errors.add(:expiry, "must look like MM/YY") unless month&.between?(1, 12)

      expires_end = Date.new(2000 + match[2].to_i, month, 1).end_of_month
      errors.add(:expiry, "is in the past") if expires_end < Date.current
    end

    def cvc_is_valid
      errors.add(:cvc, "must be 3 or 4 digits") unless cvc.to_s.strip.match?(/\A\d{3,4}\z/)
    end
end

# A saved address. Each user has at most one billing address and any number of
# shipping addresses, which have a nickname ("Home", "Work"). US only.
class Address < ApplicationRecord
  FIELDS = %i[ name line1 line2 city state postal_code ].freeze
  US_ZIP = /\A\d{5}(-\d{4})?\z/

  belongs_to :user

  enum :kind, { billing: "billing", shipping: "shipping" }, validate: true

  normalizes :name, :line1, :line2, :city, :nickname, with: ->(value) { value.squish.presence }
  normalizes :state, with: ->(value) { value.strip.upcase }
  normalizes :postal_code, with: ->(value) { value.strip }

  validates :name, :line1, :city, presence: true
  validates :state, format: { with: /\A[A-Z]{2}\z/, message: "must be a 2-letter state code, like NY" }
  validates :postal_code, format: { with: US_ZIP, message: "must be a ZIP code like 12345" }
  validates :kind, uniqueness: { scope: :user_id, message: "address is already saved" }, if: :billing?
  validates :nickname, presence: true, length: { maximum: 30 }, uniqueness: { scope: %i[ user_id kind ] }, if: :shipping?

  def self.human_attribute_name(attribute, options = {})
    { line1: "Address", line2: "Apartment, suite, etc.", postal_code: "ZIP code", name: "Full name" }
      .fetch(attribute.to_sym) { super }
  end

  # The address fields as a hash, e.g. to fill a form.
  def fields = slice(*FIELDS).symbolize_keys

  def lines
    [ name, line1, line2, "#{city}, #{state} #{postal_code}" ].compact
  end
end

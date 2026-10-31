class Subscriber < ApplicationRecord
  belongs_to :product
  # Set when a logged-in user subscribes; visitor subscriptions have no user.
  belongs_to :user, optional: true
  generates_token_for :unsubscribe

  normalizes :email, with: ->(e) { e.strip.downcase }

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { scope: :product_id }
end

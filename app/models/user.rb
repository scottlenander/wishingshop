class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :subscribers, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true

  # Non-admin users: the only accounts admins can manage.
  scope :standard, -> { where(admin: false) }

  # A user's subscriptions always use their account email.
  after_update :sync_subscriber_emails, if: :saved_change_to_email_address?

  private
    def sync_subscriber_emails
      subscribers.update_all(email: email_address)
    end
end

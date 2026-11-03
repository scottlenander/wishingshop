class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  # Users are deactivated, not deleted (see #deactivate!), and order history
  # must never go with them.
  has_many :orders, dependent: :restrict_with_exception
  has_one :cart, dependent: :destroy
  has_many :addresses, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_one :billing_address, -> { billing }, class_name: "Address", inverse_of: :user
  has_many :shipping_addresses, -> { shipping.order(:nickname) }, class_name: "Address", inverse_of: :user
  has_many :subscribers, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :first_name, :last_name, with: ->(name) { name.squish }

  validates :email_address, presence: true
  # A deactivated user keeps their email, so it can't be used for a new account.
  validates :email_address, uniqueness: true, unless: :email_on_deactivated_user?
  validate :email_not_on_deactivated_user
  validates :first_name, :last_name, presence: true, length: { maximum: 50 }

  # Non-admin users: the only accounts admins can manage.
  scope :standard, -> { where(admin: false) }
  scope :active, -> { where(deactivated_at: nil) }
  scope :deactivated, -> { where.not(deactivated_at: nil) }

  def full_name = "#{first_name} #{last_name}"

  def deactivated? = deactivated_at.present?

  # Soft delete: they can't log in and get no back-in-stock emails, but their
  # orders, reviews and email stay. Undone by an admin (Restore) or by the user
  # resetting their password.
  def deactivate!
    transaction do
      update!(deactivated_at: Time.current)
      sessions.destroy_all
    end
  end

  def reactivate!
    update!(deactivated_at: nil)
  end

  # Has ordered this product (including orders from before checkout existed).
  def purchased?(product)
    orders.joins(:order_items).exists?(order_items: { product_id: product.id })
  end

  # A user's subscriptions always use their account email.
  after_update :sync_subscriber_emails, if: :saved_change_to_email_address?

  private
    def email_on_deactivated_user?
      User.deactivated.where.not(id: id).exists?(email_address: email_address)
    end

    def email_not_on_deactivated_user
      return unless email_on_deactivated_user?

      errors.add(:email_address, "belongs to a deactivated user. Restore them from the Users page instead")
    end

    def sync_subscriber_emails
      subscribers.update_all(email: email_address)
    end
end

class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_one :cart, dependent: :destroy
  has_many :addresses, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_one :billing_address, -> { billing }, class_name: "Address", inverse_of: :user
  has_many :shipping_addresses, -> { shipping.order(:nickname) }, class_name: "Address", inverse_of: :user
  has_many :subscribers, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :first_name, :last_name, with: ->(name) { name.squish }

  validates :email_address, presence: true, uniqueness: true
  validates :first_name, :last_name, presence: true, length: { maximum: 50 }

  # Non-admin users: the only accounts admins can manage.
  scope :standard, -> { where(admin: false) }

  def full_name = "#{first_name} #{last_name}"

  # Has ordered this product (including orders from before checkout existed).
  def purchased?(product)
    orders.joins(:order_items).exists?(order_items: { product_id: product.id })
  end

  # A user's subscriptions always use their account email.
  after_update :sync_subscriber_emails, if: :saved_change_to_email_address?

  private
    def sync_subscriber_emails
      subscribers.update_all(email: email_address)
    end
end

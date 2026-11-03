module Product::Notifications
  extend ActiveSupport::Concern

  included do
    has_many :subscribers, dependent: :destroy
    after_update_commit :notify_subscribers, if: :back_in_stock?
  end

  def back_in_stock?
    inventory_count_previously_was.zero? && inventory_count.positive?
  end

  def notify_subscribers
    # Deactivated users get no emails; visitor sign-ups have no user.
    subscribers.includes(:user).each do |subscriber|
      next if subscriber.user&.deactivated?

      ProductMailer.with(product: self, subscriber: subscriber).in_stock.deliver_later
    end
  end
end

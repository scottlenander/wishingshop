# Test-data shortcuts for Playwright (e2e/libs/testData.ts), so tests can set up
# and clean up without clicking through unrelated pages. Every change made here
# is also covered by at least one test that does it through the UI.
#
# Only bin/e2e-server turns these on (E2E=1). The routes aren't drawn in
# production, and everywhere else they return 404 unless E2E=1.
class E2e::DataController < ActionController::API
  RESETTABLE = %w[ cart addresses subscriptions reviews ].freeze

  before_action :require_e2e

  # Clears what a test account has built up. `only` picks some of RESETTABLE;
  # leaving it out clears all of them.
  def reset_user
    user = User.find_by!(email_address: params.require(:email))
    parts = Array(params[:only]).presence || RESETTABLE
    unknown = parts - RESETTABLE
    return render(json: { error: "Unknown parts: #{unknown.join(", ")}" }, status: :bad_request) if unknown.any?

    user.cart&.cart_items&.destroy_all if parts.include?("cart")
    user.addresses.destroy_all if parts.include?("addresses")
    Subscriber.where(user: user).or(Subscriber.where(email: user.email_address)).destroy_all if parts.include?("subscriptions")
    user.reviews.destroy_all if parts.include?("reviews")
    head :no_content
  end

  # Deactivates (`active: false`) or reactivates a user, as Deactivate and
  # Restore on the admin Users page do.
  def set_user_active
    user = User.find_by!(email_address: params.require(:email))
    ActiveModel::Type::Boolean.new.cast(params.fetch(:active)) ? user.reactivate! : user.deactivate!
    head :no_content
  end

  # Sets a product's stock. Goes through the model, so going from 0 to more
  # emails its subscribers, as an admin edit would.
  def set_stock
    Product.find_by!(sku: params.require(:sku)).update!(inventory_count: params.require(:inventory_count))
    head :no_content
  end

  # Deletes announcements whose title starts with `title_prefix`.
  def delete_announcements
    prefix = params.require(:title_prefix)
    Announcement.where("title LIKE ?", "#{Announcement.sanitize_sql_like(prefix)}%").destroy_all
    head :no_content
  end

  # Removes every featured pick (past, current and upcoming) for a product.
  def delete_featured_products
    Product.find_by!(sku: params.require(:sku)).featured_products.destroy_all
    head :no_content
  end

  private
    def require_e2e
      head :not_found unless ENV["E2E"] == "1"
    end
end

module ApplicationHelper
  # Whole cents to dollars for display: 1999 -> "$19.99".
  def format_price(cents)
    number_to_currency(cents.to_i / 100.0)
  end
end

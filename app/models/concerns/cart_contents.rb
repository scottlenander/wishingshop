# Totals and checks shared by Cart (saved, signed-in users) and VisitorCart
# (session cookie). Each provides `items`: objects with `product`, `quantity`
# and `line_total_cents`.
module CartContents
  def item_count = items.sum(&:quantity)
  def subtotal_cents = items.sum(&:line_total_cents)
  def empty? = items.empty?

  # Reasons the cart can't be checked out yet, e.g. stock changed since adding.
  def problems
    items.filter_map do |item|
      product = item.product
      if !product.for_sale?
        "#{product.name} isn't for sale right now. Remove it to check out."
      elsif product.inventory_count.zero?
        "#{product.name} is out of stock. Remove it to check out."
      elsif item.quantity > product.inventory_count
        "Only #{product.inventory_count} #{product.name} left. Lower the quantity to check out."
      end
    end
  end

  private
    # Validates an add and returns [quantity to store, cap message or nil].
    def quantity_after_add(product, current, quantity)
      quantity = Integer(quantity, exception: false).to_i
      raise ArgumentError, "Quantity must be 1 or more" unless quantity.positive?
      raise ArgumentError, "#{product.name} isn't for sale yet" unless product.for_sale?
      raise ArgumentError, "#{product.name} is out of stock" unless product.inventory_count.positive?

      wanted = current + quantity
      stored = [ wanted, product.inventory_count ].min
      message = "Only #{product.inventory_count} #{product.name} in stock, so your cart has #{stored}." if wanted > stored
      [ stored, message ]
    end
end

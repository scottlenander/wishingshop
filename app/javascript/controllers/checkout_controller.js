import { Controller } from "@hotwired/stimulus"

// Updates the shipping cost and total on the checkout page when a shipping
// method is picked. The server always recalculates when the order is placed.
export default class extends Controller {
  static targets = ["shipping", "total"]
  static values = { subtotal: Number }

  update(event) {
    const shipping = Number(event.target.dataset.costCents)
    this.shippingTarget.textContent = shipping === 0 ? "Free" : this.format(shipping)
    this.totalTarget.textContent = this.format(this.subtotalValue + shipping)
  }

  format(cents) {
    return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" }).format(cents / 100)
  }
}

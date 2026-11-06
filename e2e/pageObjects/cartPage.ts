import { expect, type Locator, type Page } from '@playwright/test'

// Cart page (/cart). Visitors have a cart too; Checkout asks them to log in.
export class CartPage {
  readonly page: Page
  readonly header: Locator
  readonly items: Locator
  readonly emptyMessage: Locator
  readonly problems: Locator
  readonly subtotal: Locator
  readonly shippingNote: Locator
  // A link when the cart can be checked out; a disabled button when it can't.
  readonly checkoutButton: Locator

  constructor(page: Page) {
    this.page = page
    this.header = page.getByRole('heading', { name: 'Your cart' })
    this.items = page.getByTestId('cart-item')
    this.emptyMessage = page.getByText('Your cart is empty.')
    this.problems = page.getByTestId('cart-problem')
    this.subtotal = page.getByTestId('cart-subtotal')
    this.shippingNote = page.getByTestId('shipping-note')
    this.checkoutButton = page.getByTestId('cart-checkout')
  }

  async goto() {
    await this.page.goto('/cart')
  }

  item(productName: string): Locator {
    return this.items.filter({
      has: this.page.getByRole('link', { name: productName, exact: true }),
    })
  }

  quantityInput(productName: string): Locator {
    return this.page.getByRole('spinbutton', { name: `Quantity for ${productName}` })
  }

  updateButton(productName: string): Locator {
    return this.page.getByRole('button', { name: `Update ${productName}` })
  }

  removeButton(productName: string): Locator {
    return this.page.getByRole('button', { name: `Remove ${productName}` })
  }

  lineTotal(productName: string): Locator {
    return this.item(productName).getByTestId('line-total')
  }

  async setQuantity(productName: string, quantity: number) {
    await this.quantityInput(productName).fill(String(quantity))
    await this.updateButton(productName).click()
  }

  // Removes everything, so a test starts from an empty cart.
  async empty() {
    await this.goto()
    await expect(this.header).toBeVisible()
    let count = await this.items.count()
    while (count > 0) {
      await this.items
        .first()
        .getByRole('button', { name: /^Remove / })
        .click()
      // Wait for one fewer item, not the notice (it may be from the last removal).
      await expect(this.items).toHaveCount(count - 1)
      count -= 1
    }
    await expect(this.emptyMessage).toBeVisible()
  }
}

import type { Locator, Page } from '@playwright/test'

// "My orders" page (/orders): the signed-in user's purchases, newest first.
export class MyOrders {
  readonly page: Page
  readonly header: Locator
  readonly rows: Locator
  readonly emptyMessage: Locator

  constructor(page: Page) {
    this.page = page
    this.header = page.getByRole('heading', { name: 'My orders' })
    this.rows = page.locator('.admin-table tbody tr')
    this.emptyMessage = page.getByText('No orders yet.')
  }

  async goto() {
    await this.page.goto('/orders')
  }

  // Order rows for a product, newest first.
  orders(productName: string): Locator {
    return this.rows.filter({
      has: this.page.getByRole('cell', { name: productName, exact: true }),
    })
  }
}

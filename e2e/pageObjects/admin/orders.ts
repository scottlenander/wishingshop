import type { Locator, Page } from '@playwright/test'

// Admin orders (/admin/orders): every order by every customer, newest first.
export class AdminOrders {
  readonly page: Page
  readonly header: Locator
  readonly rows: Locator

  constructor(page: Page) {
    this.page = page
    this.header = page.getByRole('heading', { name: 'Orders', exact: true })
    this.rows = page.getByTestId('admin-order-row')
  }

  async goto() {
    await this.page.goto('/admin/orders')
  }

  // Rows whose text (number, customer, items...) includes this, e.g. a customer's email.
  ordersFor(text: string): Locator {
    return this.rows.filter({ hasText: text })
  }

  // The order number (e.g. "WS-1A2B3C") in the first column of a row.
  async numberOf(row: Locator): Promise<string> {
    return ((await row.getByTestId('order-number').textContent()) ?? '').trim()
  }
}

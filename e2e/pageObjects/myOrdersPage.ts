import type { Locator, Page } from '@playwright/test'

// "My orders" page (/orders): the signed-in user's purchases, newest first.
export class MyOrdersPage {
  readonly page: Page
  readonly header: Locator
  readonly rows: Locator
  readonly emptyMessage: Locator

  constructor(page: Page) {
    this.page = page
    this.header = page.getByRole('heading', { name: 'My orders' })
    this.rows = page.getByTestId('order-row')
    this.emptyMessage = page.getByText('No orders yet.')
  }

  async goto() {
    await this.page.goto('/orders')
  }

  // Order rows that include a product (items show as "2 × Scarf"), newest first.
  orders(productName: string): Locator {
    return this.rows.filter({ hasText: ` × ${productName}` })
  }

  // Row for an order number, e.g. "WS-7F3K2Q".
  order(number: string): Locator {
    return this.rows.filter({ has: this.page.getByRole('link', { name: number, exact: true }) })
  }
}

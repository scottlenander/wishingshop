import type { Locator, Page } from '@playwright/test'

// Admin subscribers (/admin/subscribers): back-in-stock sign-ups, grouped by product.
export class AdminSubscribers {
  readonly page: Page
  readonly header: Locator

  constructor(page: Page) {
    this.page = page
    this.header = page.getByRole('heading', { name: 'Subscribers', exact: true })
  }

  async goto() {
    await this.page.goto('/admin/subscribers')
  }

  // The table cell showing a subscriber's email.
  email(address: string): Locator {
    return this.page.getByRole('cell', { name: address, exact: true })
  }
}

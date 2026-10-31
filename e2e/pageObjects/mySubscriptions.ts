import type { Locator, Page } from '@playwright/test'

// "My subscriptions" page (/subscriptions): back-in-stock sign-ups.
export class MySubscriptions {
  readonly page: Page
  readonly header: Locator
  readonly rows: Locator

  constructor(page: Page) {
    this.page = page
    this.header = page.getByRole('heading', { name: 'My subscriptions' })
    this.rows = page.locator('.admin-table tbody tr')
  }

  async goto() {
    await this.page.goto('/subscriptions')
  }

  subscription(productName: string): Locator {
    return this.rows.filter({
      has: this.page.getByRole('cell', { name: productName, exact: true }),
    })
  }

  unsubscribeButton(productName: string): Locator {
    return this.subscription(productName).getByRole('button', { name: 'Unsubscribe' })
  }
}

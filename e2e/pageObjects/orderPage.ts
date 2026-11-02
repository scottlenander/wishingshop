import type { Locator, Page } from '@playwright/test'

// One order's details (/orders/WS-...), shown after checkout and from My orders.
export class OrderPage {
  readonly page: Page
  readonly header: Locator
  readonly itemRows: Locator
  readonly total: Locator
  readonly address: Locator
  readonly payment: Locator
  // "Same as shipping", or the billing address.
  readonly billing: Locator

  constructor(page: Page) {
    this.page = page
    this.header = page.getByRole('heading', { name: /^Order WS-/ })
    this.itemRows = page.locator('.order__items tbody tr')
    this.total = page.locator('.order__total')
    this.address = page.locator('.order__address')
    this.payment = page.locator('.order__payment')
    this.billing = page.locator('.order__billing')
  }

  // "WS-7F3K2Q" from the page heading.
  async number(): Promise<string> {
    const text = (await this.header.textContent()) ?? ''
    return text.replace('Order ', '').trim()
  }

  item(productName: string): Locator {
    return this.itemRows.filter({ hasText: productName })
  }
}

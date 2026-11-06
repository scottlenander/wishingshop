import { expect, type Locator, type Page } from '@playwright/test'

// "My addresses" page (/addresses): billing address and saved shipping addresses.
export class MyAddressesPage {
  readonly page: Page
  readonly header: Locator
  readonly billing: Locator
  readonly noBillingMessage: Locator
  readonly shippingCards: Locator
  readonly addShippingLink: Locator

  constructor(page: Page) {
    this.page = page
    this.header = page.getByRole('heading', { name: 'My addresses' })
    this.billing = page.getByRole('region', { name: 'Billing address' }).getByTestId('address-card')
    this.noBillingMessage = page.getByText('No billing address saved.')
    this.shippingCards = page
      .getByRole('region', { name: 'Shipping addresses' })
      .getByTestId('address-card')
    this.addShippingLink = page.getByRole('link', { name: 'Add shipping address' })
  }

  async goto() {
    await this.page.goto('/addresses')
  }

  shipping(nickname: string): Locator {
    return this.shippingCards.filter({
      has: this.page.getByRole('heading', { name: nickname, exact: true }),
    })
  }

  // Deletes every saved address, accepting each confirm dialog, so a test
  // starts clean.
  async deleteAll() {
    await this.goto()
    await expect(this.header).toBeVisible()
    const deleteButtons = this.page.getByRole('button', { name: /^Delete / })
    let count = await deleteButtons.count()
    while (count > 0) {
      this.page.once('dialog', (dialog) => void dialog.accept())
      await deleteButtons.first().click()
      // Wait for the page to reload with one fewer, not for the notice, which
      // may still be showing from the previous delete.
      await expect(deleteButtons).toHaveCount(count - 1)
      count -= 1
    }
    await expect(this.noBillingMessage).toBeVisible()
  }
}

import type { Locator, Page } from '@playwright/test'

// "Reactivate your account" (/reactivation): shown after logging in to a
// closed account. Keep the email, or type a new one.
export class ReactivationPage {
  readonly page: Page
  readonly header: Locator
  readonly emailInput: Locator
  readonly reactivateButton: Locator
  readonly error: Locator

  constructor(page: Page) {
    this.page = page
    this.header = page.getByRole('heading', { name: 'Reactivate your account' })
    this.emailInput = page.getByLabel('Email')
    this.reactivateButton = page.getByRole('button', { name: 'Reactivate my account' })
    this.error = page.getByTestId('form-error')
  }
}

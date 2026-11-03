import type { Locator, Page } from '@playwright/test'

// "Forgot password?" pages: ask for a reset email (passwords/new), then choose a
// new password from the emailed link (passwords/edit).
export class PasswordReset {
  readonly page: Page

  // Request
  readonly requestHeader: Locator
  readonly emailInput: Locator
  readonly sendButton: Locator

  // New password, from the email link
  readonly updateHeader: Locator
  readonly passwordInput: Locator
  readonly confirmationInput: Locator
  readonly saveButton: Locator

  constructor(page: Page) {
    this.page = page

    this.requestHeader = page.getByRole('heading', { name: 'Forgot your password?' })
    this.emailInput = page.getByRole('textbox', { name: 'Enter your email address' })
    this.sendButton = page.getByRole('button', { name: 'Email reset instructions' })

    this.updateHeader = page.getByRole('heading', { name: 'Update your password' })
    this.passwordInput = page.getByRole('textbox', { name: 'Enter new password' })
    this.confirmationInput = page.getByRole('textbox', { name: 'Repeat new password' })
    this.saveButton = page.getByRole('button', { name: 'Save' })
  }
}

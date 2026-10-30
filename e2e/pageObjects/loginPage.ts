import type { Locator, Page } from '@playwright/test'

// Sign-in page (sessions/new).
export class LoginPage {
  readonly page: Page
  readonly form: Locator
  readonly emailInput: Locator
  readonly passwordInput: Locator
  readonly signInButton: Locator
  readonly forgotPasswordLink: Locator

  constructor(page: Page) {
    this.page = page
    this.form = page.locator('.sessions-new__form')
    this.emailInput = page.getByRole('textbox', { name: 'Enter your email address' })
    this.passwordInput = page.getByRole('textbox', { name: 'Enter your password' })
    this.signInButton = page.getByRole('button', { name: 'Sign in' })
    this.forgotPasswordLink = page.getByRole('link', { name: 'Forgot password?' })
  }

  async goto() {
    await this.page.goto('/session/new')
  }
}

import type { Locator, Page } from '@playwright/test'

// Sign-up page (/sign_up). Signing up logs straight in.
export class SignUpPage {
  readonly page: Page
  readonly header: Locator
  readonly firstNameInput: Locator
  readonly lastNameInput: Locator
  readonly emailInput: Locator
  readonly passwordInput: Locator
  readonly confirmPasswordInput: Locator
  readonly createButton: Locator
  readonly error: Locator
  readonly logInLink: Locator

  constructor(page: Page) {
    this.page = page
    this.header = page.getByRole('heading', { name: 'Create an account' })
    this.firstNameInput = page.getByLabel('First name')
    this.lastNameInput = page.getByLabel('Last name')
    this.emailInput = page.getByLabel('Email')
    this.passwordInput = page.getByLabel('Password', { exact: true })
    this.confirmPasswordInput = page.getByLabel('Confirm password')
    this.createButton = page.getByRole('button', { name: 'Create account' })
    this.error = page.locator('.form-card .error')
    this.logInLink = page.getByRole('main').getByRole('link', { name: 'Log in' })
  }

  async goto() {
    await this.page.goto('/sign_up')
  }

  async signUp(user: { firstName: string; lastName: string; email: string; password: string }) {
    await this.firstNameInput.fill(user.firstName)
    await this.lastNameInput.fill(user.lastName)
    await this.emailInput.fill(user.email)
    await this.passwordInput.fill(user.password)
    await this.confirmPasswordInput.fill(user.password)
    await this.createButton.click()
  }
}

import type { Locator, Page } from '@playwright/test'

// My account (/account), with its Edit details (/account/edit) and Change
// password (/account/password/edit) forms. The nav greeting links here.
export class AccountPage {
  readonly page: Page

  // My account
  readonly header: Locator
  readonly details: Locator
  readonly editDetailsLink: Locator
  readonly changePasswordLink: Locator
  readonly addressesLink: Locator
  readonly closePasswordInput: Locator
  readonly closeButton: Locator

  // Edit details
  readonly editDetailsHeader: Locator
  readonly firstNameInput: Locator
  readonly lastNameInput: Locator
  readonly emailInput: Locator
  readonly saveDetailsButton: Locator

  // Change password
  readonly changePasswordHeader: Locator
  readonly newPasswordInput: Locator
  readonly confirmNewPasswordInput: Locator
  readonly changePasswordButton: Locator

  // Both forms: "Current password" (needed for an email change, a new password or closing).
  readonly currentPasswordInput: Locator
  readonly error: Locator

  constructor(page: Page) {
    this.page = page

    this.header = page.getByRole('heading', { name: 'My account', level: 1 })
    this.details = page.getByTestId('account-details')
    this.editDetailsLink = page.getByRole('link', { name: 'Edit details' })
    this.changePasswordLink = page.getByRole('link', { name: 'Change password' })
    this.addressesLink = page.getByRole('main').getByRole('link', { name: 'My addresses' })
    const closeSection = page.getByRole('region', { name: 'Close my account' })
    this.closePasswordInput = closeSection.getByLabel('Current password')
    this.closeButton = closeSection.getByRole('button', { name: 'Close my account' })

    this.editDetailsHeader = page.getByRole('heading', { name: 'Edit details', level: 1 })
    this.firstNameInput = page.getByLabel('First name')
    this.lastNameInput = page.getByLabel('Last name')
    this.emailInput = page.getByLabel('Email')
    this.saveDetailsButton = page.getByRole('button', { name: 'Save details' })

    this.changePasswordHeader = page.getByRole('heading', { name: 'Change password', level: 1 })
    this.newPasswordInput = page.getByLabel('New password', { exact: true })
    this.confirmNewPasswordInput = page.getByLabel('Confirm new password')
    this.changePasswordButton = page.getByRole('button', { name: 'Change password' })

    // On the Edit details and Change password pages (each has one).
    this.currentPasswordInput = page.getByRole('main').getByLabel('Current password')
    this.error = page.getByTestId('form-error')
  }

  async goto() {
    await this.page.goto('/account')
  }

  // Closes the account, accepting the confirm dialog.
  async close(currentPassword: string) {
    await this.closePasswordInput.fill(currentPassword)
    this.page.once('dialog', (dialog) => void dialog.accept())
    await this.closeButton.click()
  }
}

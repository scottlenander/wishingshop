import type { Locator, Page } from '@playwright/test'

// Admin users: list (/admin/users) and new/edit form. Active users are listed
// first; deactivated ones in a second "Deactivated" table with Restore.
export class AdminUsers {
  readonly page: Page

  // List
  readonly header: Locator
  readonly newLink: Locator
  readonly activeRows: Locator
  readonly deactivatedHeader: Locator
  readonly deactivatedRows: Locator

  // Form
  readonly firstNameInput: Locator
  readonly lastNameInput: Locator
  readonly emailInput: Locator
  readonly passwordInput: Locator
  readonly passwordConfirmationInput: Locator
  readonly saveButton: Locator
  readonly error: Locator

  constructor(page: Page) {
    this.page = page

    this.header = page.getByRole('heading', { name: 'Users', exact: true })
    this.newLink = page.getByRole('link', { name: 'New user' })
    this.activeRows = page.getByTestId('user-row')
    this.deactivatedHeader = page.getByRole('heading', { name: 'Deactivated' })
    this.deactivatedRows = page.getByTestId('deactivated-user-row')

    this.firstNameInput = page.getByLabel('First name')
    this.lastNameInput = page.getByLabel('Last name')
    this.emailInput = page.getByLabel('Email')
    this.passwordInput = page.getByLabel('Password', { exact: true })
    this.passwordConfirmationInput = page.getByLabel('Password confirmation')
    // "Create User" on new, "Update User" on edit.
    this.saveButton = page.getByRole('button', { name: /^(Create|Update) User$/ })
    this.error = page.getByTestId('form-error')
  }

  async goto() {
    await this.page.goto('/admin/users')
  }

  // Row in the active users table, by email.
  activeRow(email: string): Locator {
    return this.activeRows.filter({
      has: this.page.getByRole('cell', { name: email, exact: true }),
    })
  }

  deactivatedRow(email: string): Locator {
    return this.deactivatedRows.filter({
      has: this.page.getByRole('cell', { name: email, exact: true }),
    })
  }

  restoreButton(email: string): Locator {
    return this.page.getByRole('button', { name: `Restore ${email}` })
  }

  // Deactivates the user, accepting the confirm dialog.
  async deactivate(email: string) {
    this.page.once('dialog', (dialog) => void dialog.accept())
    await this.activeRow(email).getByRole('button', { name: 'Deactivate' }).click()
  }
}

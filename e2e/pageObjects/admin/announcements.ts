import type { Locator, Page } from '@playwright/test'

// Admin announcements: list (/admin/announcements) and new/edit form.
export class Announcements {
  readonly page: Page

  // List
  readonly header: Locator
  readonly newLink: Locator
  readonly rows: Locator

  // Form
  readonly kindSelect: Locator
  readonly titleInput: Locator
  readonly bodyInput: Locator
  readonly imageInput: Locator
  readonly startsInput: Locator
  readonly endsInput: Locator
  readonly positionInput: Locator
  readonly saveButton: Locator
  readonly error: Locator

  constructor(page: Page) {
    this.page = page

    this.header = page.getByRole('heading', { name: 'Announcements', exact: true })
    this.newLink = page.getByRole('link', { name: 'New announcement' })
    this.rows = page.locator('.admin-table tbody tr')

    this.kindSelect = page.getByLabel('Type')
    this.titleInput = page.getByLabel('Title')
    this.bodyInput = page.getByLabel('Message')
    this.imageInput = page.getByLabel('Image')
    this.startsInput = page.getByLabel('Starts')
    this.endsInput = page.getByLabel('Ends')
    this.positionInput = page.getByLabel('Position')
    // "Create Announcement" on new, "Update Announcement" on edit.
    this.saveButton = page.getByRole('button', { name: /^(Create|Update) Announcement$/ })
    this.error = page.locator('.form-card .error')
  }

  async goto() {
    await this.page.goto('/admin/announcements')
  }

  productCheckbox(name: string): Locator {
    return this.page.getByRole('checkbox', { name, exact: true })
  }

  row(title: string): Locator {
    return this.rows.filter({ hasText: title })
  }

  editLink(title: string): Locator {
    return this.row(title).getByRole('link', { name: 'Edit' })
  }

  deleteButton(title: string): Locator {
    return this.row(title).getByRole('button', { name: 'Delete' })
  }

  // Deletes the first row matching the title, accepting the confirm dialog.
  async delete(title: string) {
    this.page.once('dialog', (dialog) => void dialog.accept())
    await this.deleteButton(title).first().click()
  }
}

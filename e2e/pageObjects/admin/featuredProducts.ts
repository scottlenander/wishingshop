import type { Locator, Page } from '@playwright/test'

// Admin featured product picks: list (/admin/featured_products) and form.
export class FeaturedProducts {
  readonly page: Page

  // List
  readonly header: Locator
  readonly newLink: Locator
  readonly showingNow: Locator
  readonly rows: Locator

  // Form
  readonly productSelect: Locator
  readonly selectedProduct: Locator
  readonly fromInput: Locator
  readonly untilInput: Locator
  readonly saveButton: Locator
  readonly error: Locator

  constructor(page: Page) {
    this.page = page

    this.header = page.getByRole('heading', { name: 'Featured product' })
    this.newLink = page.getByRole('link', { name: 'Feature a product' })
    this.showingNow = page.locator('.admin-featured__current')
    this.rows = page.locator('.admin-table tbody tr')

    this.productSelect = page.getByLabel('Product')
    this.selectedProduct = this.productSelect.locator('option:checked')
    this.fromInput = page.getByLabel('From')
    this.untilInput = page.getByLabel('Until')
    this.saveButton = page.getByRole('button', { name: 'Save' })
    this.error = page.locator('.form-card .error')
  }

  async goto() {
    await this.page.goto('/admin/featured_products')
  }

  row(productName: string): Locator {
    return this.rows.filter({
      has: this.page.getByRole('cell', { name: productName, exact: true }),
    })
  }

  removeButton(productName: string): Locator {
    return this.row(productName).getByRole('button', { name: 'Remove' })
  }

  // Removes the first pick for this product, accepting the confirm dialog.
  async remove(productName: string) {
    this.page.once('dialog', (dialog) => void dialog.accept())
    await this.removeButton(productName).first().click()
  }
}

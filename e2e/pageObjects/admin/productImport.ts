import type { Locator, Page } from '@playwright/test'

// Admin bulk product import (/admin/product_import/new and its preview).
export class ProductImport {
  readonly page: Page

  // Upload page
  readonly header: Locator
  readonly fileInput: Locator
  readonly previewButton: Locator
  readonly templateLink: Locator
  readonly exportLink: Locator

  // Preview page
  readonly previewHeader: Locator
  readonly summary: Locator
  readonly fileErrors: Locator
  readonly rows: Locator
  readonly applyButton: Locator
  readonly uploadAgainLink: Locator

  constructor(page: Page) {
    this.page = page

    this.header = page.getByRole('heading', { name: 'Import products' })
    this.fileInput = page.getByLabel('CSV file')
    this.previewButton = page.getByRole('button', { name: 'Preview import' })
    this.templateLink = page.getByRole('link', { name: 'Download a blank template' })
    this.exportLink = page.getByRole('link', { name: 'export current products' })

    this.previewHeader = page.getByRole('heading', { name: 'Import preview' })
    this.summary = page.locator('.admin-import__summary')
    this.fileErrors = page.locator('main .error')
    this.rows = page.locator('.admin-import__table tbody tr')
    this.applyButton = page.getByRole('button', { name: 'Apply import' })
    this.uploadAgainLink = page.getByRole('link', { name: 'Upload again' })
  }

  async goto() {
    await this.page.goto('/admin/product_import/new')
  }

  // Count in the summary, e.g. summaryCount('to create') -> "1 to create".
  summaryCount(label: 'to create' | 'to update' | 'unchanged' | 'with errors'): Locator {
    return this.summary.getByRole('listitem').filter({ hasText: label })
  }

  // Preview row for a CSV line (the header is line 1).
  row(line: number): Locator {
    return this.page.locator(`.admin-import__table tr[data-line="${line}"]`)
  }

  // Uploads CSV text as a file, without writing it to disk.
  // Call on the upload page (wait for `header` first after navigating).
  async upload(csv: string, filename = 'products.csv') {
    await this.fileInput.setInputFiles({
      name: filename,
      mimeType: 'text/csv',
      buffer: Buffer.from(csv),
    })
    await this.previewButton.click()
  }
}

import type { Locator, Page } from '@playwright/test'

// Product list on the home page (products/index).
export class Products {
  readonly page: Page
  readonly header: Locator
  readonly grid: Locator
  readonly newProductLink: Locator
  readonly item: Item

  constructor(page: Page) {
    this.page = page
    this.header = page.getByRole('heading', { name: 'Products' })
    this.grid = page.locator('.products-index__grid')
    this.newProductLink = page.getByRole('link', { name: 'New product' }) // admins only
    this.item = new Item(page)
  }

  card(name: string): IndexCard {
    return new IndexCard(
      this.grid
        .locator('.products-index__card')
        .filter({ has: this.page.getByRole('link', { name, exact: true }) }),
    )
  }
}

// One product card in the grid, found by product name.
export class IndexCard {
  readonly root: Locator
  readonly image: Locator
  readonly link: Locator

  constructor(root: Locator) {
    this.root = root
    this.image = root.locator('img')
    this.link = root.getByRole('link')
  }
}

// Single product page (products/show).
export class Item {
  readonly root: Locator
  readonly backLink: Locator
  readonly image: Locator
  readonly title: Locator
  readonly description: Locator
  readonly stockStatus: Locator
  readonly inStock: Locator
  readonly outOfStock: Locator
  readonly subscribeEmail: Locator
  readonly subscribeButton: Locator
  readonly editLink: Locator
  readonly deleteButton: Locator

  constructor(page: Page) {
    this.root = page.locator('.products-show__product')
    this.backLink = page.getByRole('link', { name: 'Back' })
    this.image = this.root.getByRole('img')
    this.title = this.root.getByRole('heading', { level: 1 })
    this.description = this.root.locator('.products-show__description')

    // Stock: one of inStock ("12 in stock") or outOfStock is shown.
    this.stockStatus = this.root.locator('.products-inventory__status')
    this.inStock = this.root.locator('.products-inventory__status--in-stock')
    this.outOfStock = this.root.locator('.products-inventory__status--out-of-stock')

    // Back-in-stock form, only shown when out of stock.
    this.subscribeEmail = this.root.getByPlaceholder('you@example.com')
    this.subscribeButton = this.root.getByRole('button', { name: 'Submit' })

    // Admins only.
    this.editLink = this.root.getByRole('link', { name: 'Edit' })
    this.deleteButton = this.root.getByRole('button', { name: 'Delete' })
  }
}

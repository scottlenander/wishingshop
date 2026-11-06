import { expect, type Locator, type Page } from '@playwright/test'
import { Reviews } from './reviews'

// Product list on the home page (products/index).
export class Products {
  readonly page: Page
  readonly header: Locator
  readonly grid: Locator
  // Headings of the category sections, in page order ("Tops", "Bottoms"...).
  readonly categoryTitles: Locator
  readonly newProductLink: Locator
  readonly item: Item
  readonly form: ProductForm

  constructor(page: Page) {
    this.page = page
    this.header = page.getByRole('heading', { name: 'Products' })
    // One grid per category section; card() looks across all of them.
    this.grid = page.getByTestId('product-grid')
    this.categoryTitles = page.getByTestId('category-title')
    this.newProductLink = page.getByRole('link', { name: 'New product' }) // admins only
    this.item = new Item(page)
    this.form = new ProductForm(page)
  }

  card(name: string): IndexCard {
    return new IndexCard(
      this.grid
        .getByTestId('product-card')
        .filter({ has: this.page.getByRole('link', { name, exact: true }) }),
    )
  }

  // A category section, found by its heading, e.g. category('Tops').
  category(label: string): Locator {
    return this.page.getByRole('region', { name: label, exact: true })
  }

  // Goes to the home page and opens a product from its card.
  async open(name: string) {
    await this.page.goto('/')
    await this.card(name).link.click()
    await expect(this.item.title).toHaveText(name)
  }
}

// One product card in the grid, found by product name.
export class IndexCard {
  readonly root: Locator
  readonly image: Locator
  readonly link: Locator
  // Stars named "Rated 4.0 out of 5 from 8 reviews", or "Not yet rated".
  readonly rating: Locator
  readonly notRated: Locator

  constructor(root: Locator) {
    this.root = root
    this.image = root.getByTestId('product-card-image')
    this.link = root.getByRole('link')
    this.rating = root.getByRole('img', { name: /^Rated / })
    this.notRated = root.getByText('Not yet rated')
  }
}

// Single product page (products/show).
export class Item {
  readonly root: Locator
  readonly backLink: Locator
  readonly image: Locator
  readonly title: Locator
  // Above the title, e.g. "Tops", linking to that section of the products page.
  readonly categoryLink: Locator
  readonly description: Locator
  // Under the title: "4.0 out of 5 · 8 reviews", a link down to the reviews, or "Not yet rated".
  readonly ratingLink: Locator
  readonly notRated: Locator
  readonly stockStatus: Locator
  readonly inStock: Locator
  readonly outOfStock: Locator
  readonly price: Locator
  readonly quantityInput: Locator
  readonly addToCartButton: Locator
  readonly notifyButton: Locator
  readonly unsubscribeButton: Locator
  readonly subscribedMessage: Locator
  readonly subscribeEmail: Locator
  readonly subscribeButton: Locator
  readonly editLink: Locator
  readonly featureLink: Locator
  readonly deleteButton: Locator
  readonly reviews: Reviews

  constructor(page: Page) {
    this.root = page.getByTestId('product-details')
    this.backLink = page.getByRole('link', { name: 'Back' })
    this.image = this.root.getByRole('img')
    this.title = this.root.getByRole('heading', { level: 1 })
    this.categoryLink = this.root.getByRole('link', { name: /^Category: / })
    this.description = this.root.getByTestId('product-description')

    // Stock: one of inStock ("12 in stock") or outOfStock is shown.
    this.ratingLink = this.root.getByRole('link', { name: /out of 5 · \d+ reviews?$/ })
    this.notRated = this.root.getByTestId('product-rating').getByText('Not yet rated')
    this.inStock = this.root.getByTestId('in-stock')
    this.outOfStock = this.root.getByTestId('out-of-stock')
    this.stockStatus = this.inStock.or(this.outOfStock)

    // Price ("$19.99", or "Not for sale yet").
    this.price = this.root.getByTestId('product-price')

    // In stock: anyone can add to the cart (visitors log in at checkout).
    this.quantityInput = this.root.getByLabel('Quantity')
    this.addToCartButton = this.root.getByRole('button', { name: 'Add to cart' })

    // Out of stock, signed in: one-click subscribe / unsubscribe.
    this.notifyButton = this.root.getByRole('button', { name: 'Notify me' })
    this.unsubscribeButton = this.root.getByRole('button', { name: 'Unsubscribe' })
    this.subscribedMessage = this.root.getByText("We'll email you when it's back.")

    // Out of stock, visitor: back-in-stock email form.
    this.subscribeEmail = this.root.getByPlaceholder('you@example.com')
    this.subscribeButton = this.root.getByRole('button', { name: 'Submit' })

    // Admins only.
    this.editLink = this.root.getByRole('link', { name: 'Edit' })
    this.featureLink = this.root.getByRole('link', { name: 'Feature this product' })
    this.deleteButton = this.root.getByRole('button', { name: 'Delete' })

    // Below the product card.
    this.reviews = new Reviews(page)
  }

  // Admins only: deletes the product, accepting the confirm dialog.
  async deleteProduct() {
    this.root.page().once('dialog', (dialog) => void dialog.accept())
    await this.deleteButton.click()
  }
}

// New/edit product form (products/new, products/edit). Admins only.
export class ProductForm {
  readonly root: Locator
  readonly error: Locator
  readonly nameInput: Locator
  readonly categorySelect: Locator
  readonly skuInput: Locator
  readonly imageInput: Locator
  readonly priceInput: Locator
  readonly inventoryInput: Locator
  readonly saveButton: Locator
  readonly cancelLink: Locator

  constructor(page: Page) {
    this.root = page.getByTestId('product-form')
    this.error = this.root.getByTestId('form-error')
    this.nameInput = this.root.getByLabel('Name')
    this.categorySelect = this.root.getByLabel('Category')
    this.skuInput = this.root.getByLabel('SKU')
    this.imageInput = this.root.getByLabel('Featured image')
    this.priceInput = this.root.getByLabel('Price ($)')
    this.inventoryInput = this.root.getByLabel('Inventory count')
    // "Create Product" on new, "Update Product" on edit.
    this.saveButton = this.root.getByRole('button', { name: /^(Create|Update) Product$/ })
    this.cancelLink = page.getByRole('link', { name: 'Cancel' })
  }
}

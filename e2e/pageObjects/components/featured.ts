import type { Locator, Page } from '@playwright/test'

// Featured product card beside the carousel on the products page.
export class Featured {
  readonly root: Locator
  readonly label: Locator
  readonly image: Locator
  readonly title: Locator
  readonly description: Locator
  readonly stockStatus: Locator
  readonly pickedNote: Locator
  // Stars named "Rated 4.0 out of 5 from 8 reviews", or "Not yet rated".
  readonly rating: Locator
  readonly notRated: Locator
  readonly link: Locator

  constructor(page: Page) {
    this.root = page.locator('.products-featured')
    this.label = this.root.getByText('Featured', { exact: true })
    this.image = this.root.locator('.products-featured__image')
    this.title = this.root.getByRole('heading', { level: 2 })
    this.description = this.root.locator('.products-featured__description')
    this.stockStatus = this.root.locator('.products-inventory__status')
    // Only shown for admin picks, not the daily random pick.
    this.pickedNote = this.root.getByText('Picked by our team')
    this.link = this.root.getByRole('link', { name: /^View / })
    this.rating = this.root.getByRole('img', { name: /^Rated / })
    this.notRated = this.root.getByText('Not yet rated')
  }
}

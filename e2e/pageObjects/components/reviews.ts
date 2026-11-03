import type { Locator, Page } from '@playwright/test'

// Reviews section on the product page (below the product card).
export class Reviews {
  readonly page: Page
  readonly root: Locator

  // Summary
  readonly average: Locator
  readonly count: Locator

  // List: the 3 newest, then "Show more reviews (N more)" adds 10 at a time.
  readonly items: Locator
  readonly showMoreButton: Locator
  readonly emptyMessage: Locator

  // Write a review / why you can't
  readonly compose: Locator
  readonly loginToReviewLink: Locator
  readonly notEligibleMessage: Locator
  readonly bodyInput: Locator
  readonly submitButton: Locator
  readonly formErrors: Locator
  readonly yourReview: Locator
  readonly editLink: Locator
  readonly deleteButton: Locator

  constructor(page: Page) {
    this.page = page
    this.root = page.getByRole('region', { name: 'Reviews' })

    this.average = this.root.locator('.reviews-summary__average strong')
    this.count = this.root.locator('.reviews-summary__count')

    this.items = this.root.locator('.reviews-item')
    this.showMoreButton = this.root.getByRole('link', { name: /^Show more reviews/ })
    this.emptyMessage = this.root.locator('.reviews__empty')

    this.compose = this.root.locator('#write-review')
    this.loginToReviewLink = this.compose.getByRole('link', { name: 'Log in to write a review' })
    this.notEligibleMessage = this.compose.getByText(
      'Only customers who bought this can review it.',
    )
    this.bodyInput = page.getByLabel('Your review')
    this.submitButton = page.getByRole('button', { name: /^(Post|Update) review$/ })
    this.formErrors = page.locator('.reviews-form .error')
    this.yourReview = this.compose.getByRole('heading', { name: 'Your review' })
    this.editLink = this.compose.getByRole('link', { name: 'Edit your review' })
    this.deleteButton = this.compose.getByRole('button', { name: 'Delete your review' })
  }

  // Star picker radio, e.g. rating(4) is "4 stars".
  rating(stars: number): Locator {
    return this.page.getByRole('radio', {
      name: stars === 1 ? '1 star' : `${stars} stars`,
      exact: true,
    })
  }

  // Bar in the summary, e.g. breakdown(5) is named "5 stars: 3 reviews".
  breakdown(stars: number): Locator {
    return this.root.getByRole('meter', { name: new RegExp(`^${stars} stars?:`) })
  }

  review(text: string): Locator {
    return this.items.filter({ hasText: text })
  }

  // Stars shown on a review, named "4 out of 5 stars".
  stars(review: Locator): Locator {
    return review.getByRole('img', { name: /out of 5 stars$/ })
  }

  // Picks the stars and posts (or updates) the review.
  async write(stars: number, text: string) {
    // The radios are drawn as stars; click the star (label) like a person would.
    await this.page.locator(`label[for="review_rating_${stars}"]`).click()
    await this.bodyInput.fill(text)
    await this.submitButton.click()
  }

  // Deletes the signed-in user's review if there is one, accepting the dialog.
  async deleteMine() {
    if (await this.deleteButton.isVisible()) {
      this.page.once('dialog', (dialog) => void dialog.accept())
      await this.deleteButton.click()
      await this.page.locator('.notice').getByText('Review deleted.').waitFor()
    }
  }
}

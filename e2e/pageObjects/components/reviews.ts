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

  // Sort links and the star filter (picked from the summary bars).
  readonly sortNav: Locator
  readonly filterNote: Locator
  readonly showAllLink: Locator

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

    this.average = this.root.getByTestId('rating-average')
    this.count = this.root.getByTestId('review-count')

    this.items = this.root.getByTestId('review')
    this.showMoreButton = this.root.getByRole('link', { name: /^Show more reviews/ })
    this.emptyMessage = this.root.getByTestId('reviews-empty')

    this.sortNav = this.root.getByRole('navigation', { name: 'Sort reviews' })
    this.filterNote = this.root.getByTestId('review-filter-note')
    this.showAllLink = this.root.getByRole('link', { name: 'Show all reviews' })

    this.compose = this.root.locator('#write-review')
    this.loginToReviewLink = this.compose.getByRole('link', { name: 'Log in to write a review' })
    this.notEligibleMessage = this.compose.getByText(
      'Only customers who bought this can review it.',
    )
    this.bodyInput = page.getByLabel('Your review')
    this.submitButton = page.getByRole('button', { name: /^(Post|Update) review$/ })
    this.formErrors = page.getByTestId('form-error')
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

  // 'Newest', 'Highest rated' or 'Lowest rated'. The current one has aria-current.
  sortLink(label: string): Locator {
    return this.sortNav.getByRole('link', { name: label, exact: true })
  }

  // The "5 stars" label beside a summary bar: shows only reviews with that many stars.
  filterLink(stars: number): Locator {
    return this.root.getByRole('link', { name: new RegExp(`^${stars} stars?: show only these`) })
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

  // Admins only: the Delete button on someone else's review, named "Delete review by Mo M.".
  adminDeleteButton(authorName: string): Locator {
    return this.items.getByRole('button', { name: `Delete review by ${authorName}` })
  }

  // Admins only: deletes someone else's review, accepting the confirm dialog.
  async adminDelete(authorName: string) {
    this.page.once('dialog', (dialog) => void dialog.accept())
    await this.adminDeleteButton(authorName).click()
  }

  // Deletes the signed-in user's review if there is one, accepting the dialog.
  async deleteMine() {
    if (await this.deleteButton.isVisible()) {
      this.page.once('dialog', (dialog) => void dialog.accept())
      await this.deleteButton.click()
      await this.page.getByTestId('flash-notice').getByText('Review deleted.').waitFor()
    }
  }
}

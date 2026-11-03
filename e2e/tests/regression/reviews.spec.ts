import { test, expect } from '@playwright/test'
import { MainPage } from '../../pageObjects/mainPage'
import { PRODUCTS, SEEDED_REVIEWS, USERS } from '../../libs/constants'
import { AUTH_FILES } from '../../libs/auth'
import { TestData } from '../../libs/testData'

// The reviews account has a seeded order of this.
const REVIEWED = PRODUCTS.GRAPHIC_TEE.name
const BUYER = USERS.reviews
// Has the 8 seeded reviews; only read here.
const SEEDED = PRODUCTS.T_SHIRT.name
// No reviews; only read here.
const UNRATED = PRODUCTS.WOOL_SWEATER.name

test.describe('a buyer', () => {
  // This test writes and deletes the buyer's review, so its steps run in order.
  test.describe.configure({ mode: 'serial' })
  test.use({ storageState: AUTH_FILES.reviews })

  test('writes, edits and deletes a review', async ({ page, request }) => {
    const mainPage = new MainPage(page)
    const { products } = mainPage
    const { reviews } = products.item
    const text = `Bold print and comfy fit. Test run ${Date.now()}.`
    let countBefore = 0

    await test.step('Open the product, with no review from an earlier run', async () => {
      await new TestData(request).resetUser(BUYER.email, ['reviews'])
      await products.open(REVIEWED)
      await expect(reviews.submitButton).toBeVisible()
      countBefore = await reviews.items.count()
    })

    await test.step('Too-short text is stopped and kept', async () => {
      // The browser blocks it (minlength); the server's own check is covered by Rails tests.
      await reviews.write(4, 'Too short')
      expect(
        await reviews.bodyInput.evaluate((el: HTMLTextAreaElement) => el.validity.tooShort),
      ).toBe(true)
      await expect(reviews.bodyInput).toHaveValue('Too short')
      await expect(reviews.rating(4)).toBeChecked()
      await expect(reviews.items).toHaveCount(countBefore)
    })

    await test.step('Post a 4-star review', async () => {
      await reviews.write(4, text)
      await expect(mainPage.notice).toHaveText('Thanks for your review!')

      const mine = reviews.items.first()
      await expect(mine).toContainText(text)
      await expect(mine).toContainText(`${BUYER.firstName} ${BUYER.lastName[0]}.`)
      await expect(mine).toContainText('Verified purchase')
      await expect(reviews.stars(mine)).toHaveAccessibleName('4 out of 5 stars')
      await expect(reviews.items).toHaveCount(Math.min(countBefore + 1, 3))
      await expect(reviews.yourReview).toBeVisible()
    })

    await test.step('Edit it to 5 stars', async () => {
      await reviews.editLink.click()
      await expect(reviews.rating(4)).toBeChecked()
      await reviews.write(5, `${text} Even better after washing.`)
      await expect(mainPage.notice).toHaveText('Review updated.')
      await expect(reviews.stars(reviews.review(text))).toHaveAccessibleName('5 out of 5 stars')
    })

    await test.step('Delete it', async () => {
      await reviews.deleteMine()
      await expect(reviews.review(text)).toHaveCount(0)
      await expect(reviews.submitButton).toBeVisible()
    })
  })
})

test.describe('a signed-in user who has not bought it', () => {
  test.use({ storageState: AUTH_FILES.reviewsNonBuyer })

  test("sees why they can't review", async ({ page }) => {
    const mainPage = new MainPage(page)
    const { reviews } = mainPage.products.item

    await mainPage.products.open(REVIEWED)
    await expect(reviews.notEligibleMessage).toBeVisible()
    await expect(reviews.submitButton).toHaveCount(0)
  })
})

test('a visitor reads reviews and loads more', async ({ page }) => {
  const mainPage = new MainPage(page)
  const { reviews } = mainPage.products.item

  await test.step('Product cards show the rating, or not yet rated', async () => {
    await mainPage.goto()
    const { products } = mainPage
    await expect(products.card(SEEDED).rating).toHaveAccessibleName(
      `Rated ${SEEDED_REVIEWS.tShirtAverage} out of 5 from ${SEEDED_REVIEWS.tShirtCount} reviews`,
    )
    await expect(products.card(SEEDED).root).toContainText(
      `${SEEDED_REVIEWS.tShirtAverage} (${SEEDED_REVIEWS.tShirtCount})`,
    )
    await expect(products.card(UNRATED).notRated).toBeVisible()
    await expect(products.card(UNRATED).rating).toHaveCount(0)
  })

  await test.step('The 3 newest show, with a summary', async () => {
    await mainPage.products.card(SEEDED).link.click()

    await expect(reviews.average).toHaveText(`${SEEDED_REVIEWS.tShirtAverage} out of 5`)
    await expect(reviews.count).toHaveText(`${SEEDED_REVIEWS.tShirtCount} reviews`)
    await expect(reviews.breakdown(5)).toBeVisible()
    await expect(reviews.items).toHaveCount(3)
    await expect(reviews.loginToReviewLink).toBeVisible()
  })

  await test.step('Show more loads the rest on the same page', async () => {
    const url = page.url()
    await expect(reviews.showMoreButton).toHaveText(
      `Show more reviews (${SEEDED_REVIEWS.tShirtCount - 3} more)`,
    )
    await reviews.showMoreButton.click()

    await expect(reviews.items).toHaveCount(SEEDED_REVIEWS.tShirtCount)
    await expect(reviews.showMoreButton).toHaveCount(0)
    expect(page.url(), 'stays on the product page').toBe(url)
  })
})

import { test, expect } from '@playwright/test'
import { MainPage } from '../../pageObjects/mainPage'
import { PRODUCTS, USERS } from '../../libs/constants'
import { AUTH_FILES } from '../../libs/auth'
import { TestData } from '../../libs/testData'

// The review-moderation account has a seeded order of this, and nobody else reviews it.
const PRODUCT = PRODUCTS.FLANNEL_SHIRT.name
const CUSTOMER = USERS.reviewModeration
const AUTHOR_NAME = `${CUSTOMER.firstName} ${CUSTOMER.lastName[0]}.`

// Writes then deletes a review on shared data, so the steps run in order.
test.describe.configure({ mode: 'serial' })

// Starts signed in as admin; the customer uses a second browser.
test.use({ storageState: AUTH_FILES.admin })

test("admin deletes a customer's review", async ({ page, browser, request }) => {
  const mainPage = new MainPage(page)
  const { products } = mainPage
  const { reviews } = products.item
  const text = `Shrank in the wash. Test run ${Date.now()}.`

  await test.step('Start with no reviews from an earlier run', async () => {
    await new TestData(request).resetUser(CUSTOMER.email, ['reviews'])
  })

  await test.step('The customer posts a 2-star review', async () => {
    const context = await browser.newContext({ storageState: AUTH_FILES.reviewModeration })
    const customerPage = new MainPage(await context.newPage())
    await customerPage.products.open(PRODUCT)
    await customerPage.products.item.reviews.write(2, text)
    await expect(customerPage.notice).toHaveText('Thanks for your review!')
    await context.close()
  })

  await test.step('Admin sees it, with a Delete button', async () => {
    await products.open(PRODUCT)
    await expect(reviews.review(text)).toBeVisible()
    await expect(reviews.count).toHaveText('1 review')
    await expect(reviews.average).toHaveText('2.0 out of 5')
    // Admins have no review box of their own here: they haven't bought it.
    await expect(reviews.notEligibleMessage).toBeVisible()
  })

  await test.step('Admin deletes it; the summary and card update', async () => {
    await reviews.adminDelete(AUTHOR_NAME)
    await expect(mainPage.notice).toHaveText('Review deleted.')
    await expect(reviews.review(text)).toHaveCount(0)
    await expect(reviews.emptyMessage).toHaveText('No reviews yet.')

    await mainPage.goto()
    await expect(products.card(PRODUCT).notRated).toBeVisible()
  })
})

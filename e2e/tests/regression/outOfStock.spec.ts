import { test, expect } from '@playwright/test'
import { MainPage } from '../../pageObjects/mainPage'
import { AUTH_FILES } from '../../libs/auth'
import { LetterOpener } from '../../pageObjects/letterOpener'
import { PRODUCTS, USERS } from '../../libs/constants'

// Seeded out of stock.
const PRODUCT = PRODUCTS.HOODIE.name

// This test changes shared data (stock), so don't run its steps in parallel.
test.describe.configure({ mode: 'serial' })

// Starts signed in as Alice; the admin context uses the saved admin session
// (see tests/auth.setup.ts).
test.use({ storageState: AUTH_FILES.alice })

test('subscriber is emailed when an out-of-stock item is restocked', async ({ page, browser }) => {
  // Standard user
  const mainPage = new MainPage(page)
  const letterOpener = new LetterOpener(page)
  const { products } = mainPage
  const { item } = products

  // Admin, in a separate browser context so the standard user stays logged in.
  // Stock changes go through the app, so Rails sends the back-in-stock email.
  const adminContext = await browser.newContext({ storageState: AUTH_FILES.admin })
  const adminPage = await adminContext.newPage()
  const adminMainPage = new MainPage(adminPage)
  const adminProducts = adminMainPage.products

  // Signed-in users subscribe with their account email.
  const subscriberEmail = USERS.alice.email
  let lettersBefore = 0

  await test.step('Admin makes sure the item starts out of stock', async () => {
    // Lets the test be re-run against the same server without reseeding.
    await adminProducts.open(PRODUCT)
    await adminProducts.item.editLink.click()
    await adminProducts.form.inventoryInput.fill('0')
    await adminProducts.form.saveButton.click()
    await expect(adminProducts.item.outOfStock).toBeVisible()
  })

  await test.step('Standard user opens the out-of-stock item', async () => {
    await mainPage.goto()
    await expect(mainPage.logoutButton).toBeVisible()

    await products.card(PRODUCT).link.click()
    await expect(item.title).toHaveText(PRODUCT)
    await expect(item.outOfStock, { message: `${PRODUCT} should be out of stock` }).toBeVisible()
  })

  await test.step('Subscribe to the back-in-stock email', async () => {
    // A previous run may have left Alice subscribed; start from not subscribed.
    // Wait for either button first, so the check below sees the loaded page.
    await expect(item.notifyButton.or(item.unsubscribeButton)).toBeVisible()
    if (await item.unsubscribeButton.isVisible()) {
      await item.unsubscribeButton.click()
      await expect(item.notifyButton).toBeVisible()
    }

    await item.notifyButton.click()
    await expect(mainPage.notice).toHaveText('You are now subscribed.')
    await expect(item.subscribedMessage).toBeVisible()
  })

  await test.step("Count Alice's emails before the restock", async () => {
    // Earlier runs leave emails to Alice in the inbox, so look for one more.
    await letterOpener.goto()
    lettersBefore = await letterOpener.letter(subscriberEmail).count()
    await page.goBack()
  })

  await test.step('Admin restocks the item', async () => {
    await adminProducts.item.editLink.click()
    await adminProducts.form.inventoryInput.fill('10')
    await adminProducts.form.saveButton.click()
    await expect(adminProducts.item.inStock).toHaveText('10 in stock')
    await adminContext.close()

    await page.reload()
    await expect(item.inStock).toHaveText('10 in stock')
  })

  await test.step('Subscriber receives the email', async () => {
    await letterOpener.goto()
    await letterOpener.waitForLetters(subscriberEmail, lettersBefore + 1)

    // Newest email is listed first.
    await letterOpener.letter(subscriberEmail).first().click()
    await expect(letterOpener.mailBody.getByText(`${PRODUCT} is back in stock.`)).toBeVisible()
    await expect(letterOpener.mailBody.getByRole('link', { name: 'Unsubscribe' })).toBeVisible()
  })
})

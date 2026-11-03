import { test, expect } from '@playwright/test'
import { MainPage } from '../../pageObjects/mainPage'
import { MySubscriptions } from '../../pageObjects/mySubscriptions'
import { AUTH_FILES } from '../../libs/auth'
import { LetterOpener } from '../../pageObjects/letterOpener'
import { PRODUCTS, USERS } from '../../libs/constants'
import { TestData } from '../../libs/testData'

// Seeded out of stock.
const PRODUCT = PRODUCTS.HOODIE.name

// This test changes shared data (stock), so don't run its steps in parallel.
test.describe.configure({ mode: 'serial' })

// Starts signed in as the out-of-stock account; the admin context uses the saved
// admin session (see tests/auth.setup.ts).
test.use({ storageState: AUTH_FILES.outOfStock })

test('subscriber is emailed when an out-of-stock item is restocked', async ({
  page,
  browser,
  request,
}) => {
  // Standard user
  const mainPage = new MainPage(page)
  const letterOpener = new LetterOpener(page)
  const mySubscriptions = new MySubscriptions(page)
  const testData = new TestData(request)
  const { products } = mainPage
  const { item } = products

  // Signed-in users subscribe with their account email.
  const subscriberEmail = USERS.outOfStock.email
  let lettersBefore = 0

  await test.step('Start out of stock and not subscribed', async () => {
    // Lets the test be re-run against the same server without reseeding.
    await testData.setStock(PRODUCTS.HOODIE.sku, 0)
    await testData.resetUser(subscriberEmail, ['subscriptions'])
  })

  await test.step('Standard user opens the out-of-stock item', async () => {
    await mainPage.goto()
    await expect(mainPage.logoutButton).toBeVisible()

    await products.card(PRODUCT).link.click()
    await expect(item.title).toHaveText(PRODUCT)
    await expect(item.outOfStock, { message: `${PRODUCT} should be out of stock` }).toBeVisible()
  })

  await test.step('Subscribe to the back-in-stock email', async () => {
    await item.notifyButton.click()
    await expect(mainPage.notice).toHaveText('You are now subscribed.')
    await expect(item.subscribedMessage).toBeVisible()
  })

  await test.step('Count their emails before the restock', async () => {
    // Earlier runs leave emails to this address in the inbox, so look for one more.
    await letterOpener.goto()
    lettersBefore = await letterOpener.letter(subscriberEmail).count()
    await page.goBack()
  })

  await test.step('Admin restocks the item', async () => {
    // Through the admin form, in a separate browser so the subscriber stays logged in.
    const adminContext = await browser.newContext({ storageState: AUTH_FILES.admin })
    const adminProducts = new MainPage(await adminContext.newPage()).products
    await adminProducts.open(PRODUCT)
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

    await letterOpener.openLetter(subscriberEmail)
    await expect(letterOpener.mailBody.getByText(`${PRODUCT} is back in stock.`)).toBeVisible()
    await expect(letterOpener.mailBody.getByRole('link', { name: 'Unsubscribe' })).toBeVisible()
  })

  await test.step('Unsubscribe from My subscriptions', async () => {
    await mySubscriptions.goto()
    await mySubscriptions.unsubscribeButton(PRODUCT).click()
    await expect(mainPage.notice).toHaveText(`Unsubscribed from ${PRODUCT}.`)
    await expect(mySubscriptions.subscription(PRODUCT)).toHaveCount(0)
  })
})

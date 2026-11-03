import { test, expect } from '@playwright/test'
import { MainPage } from '../../pageObjects/mainPage'
import { LetterOpener } from '../../pageObjects/letterOpener'
import { AdminSubscribers } from '../../pageObjects/admin/subscribers'
import { PRODUCTS } from '../../libs/constants'
import { AUTH_FILES } from '../../libs/auth'
import { TestData } from '../../libs/testData'

// Only this test changes its stock.
const PRODUCT = PRODUCTS.PUFFER_VEST

// Changes the Puffer Vest's stock, so the steps run in order.
test.describe.configure({ mode: 'serial' })

test('a visitor subscribes by email and unsubscribes from the email link', async ({
  page,
  browser,
  request,
}) => {
  const mainPage = new MainPage(page)
  const letterOpener = new LetterOpener(page)
  const testData = new TestData(request)
  const { item } = mainPage.products
  // New every run, so the inbox has exactly one email for it.
  const email = `visitor-${Date.now()}@example.com`

  // The admin checks the subscriber list in a second browser.
  const adminContext = await browser.newContext({ storageState: AUTH_FILES.admin })
  const subscribers = new AdminSubscribers(await adminContext.newPage())

  await test.step('Start out of stock', async () => {
    await testData.setStock(PRODUCT.sku, 0)
  })

  await test.step('A visitor types their email to be told when it is back', async () => {
    await mainPage.products.open(PRODUCT.name)
    await expect(item.outOfStock).toBeVisible()
    await item.subscribeEmail.fill(email)
    await item.subscribeButton.click()
    await expect(mainPage.notice).toHaveText('You are now subscribed.')

    await subscribers.goto()
    await expect(subscribers.email(email)).toBeVisible()
  })

  await test.step('A restock emails them', async () => {
    // Restocking through the admin form is tested in outOfStock.spec.ts.
    await testData.setStock(PRODUCT.sku, 5)
    await letterOpener.goto()
    await letterOpener.waitForLetters(email, 1)
    await letterOpener.openLetter(email)
    await expect(letterOpener.mailBody.getByText(`${PRODUCT.name} is back in stock.`)).toBeVisible()
  })

  await test.step('The Unsubscribe link in the email removes them', async () => {
    const href = await letterOpener.mailBody
      .getByRole('link', { name: 'Unsubscribe' })
      .getAttribute('href')
    expect(href, 'the link points at this server').toMatch(/^http:\/\/localhost:\d+\/unsubscribe/)
    await page.goto(href ?? '')
    await expect(mainPage.notice).toHaveText('Unsubscribed successfully.')

    await subscribers.goto()
    await expect(subscribers.email(email)).toHaveCount(0)
    await adminContext.close()
  })
})

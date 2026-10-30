import { test, expect } from '@playwright/test'
import { MainPage } from '../../pageObjects/mainPage'
import { LoginPage } from '../../pageObjects/loginPage'
import { LetterOpener } from '../../pageObjects/letterOpener'

// Seeded out of stock.
const PRODUCT = 'Hoodie'

// This test changes shared data (stock), so don't run its steps in parallel.
test.describe.configure({ mode: 'serial' })

test('subscriber is emailed when an out-of-stock item is restocked', async ({ page, browser }) => {
  // Standard user
  const mainPage = new MainPage(page)
  const loginPage = new LoginPage(page)
  const letterOpener = new LetterOpener(page)
  const { products } = mainPage
  const { item } = products

  // Admin, in a separate browser context so the standard user stays logged in.
  // Stock changes go through the app, so Rails sends the back-in-stock email.
  const adminContext = await browser.newContext()
  const adminPage = await adminContext.newPage()
  const adminMainPage = new MainPage(adminPage)
  const adminLoginPage = new LoginPage(adminPage)
  const adminProducts = adminMainPage.products

  const subscriberEmail = `alice+${Date.now()}@example.com`

  await test.step('Admin makes sure the item starts out of stock', async () => {
    await adminLoginPage.goto()
    await adminLoginPage.emailInput.fill('admin@example.com')
    await adminLoginPage.passwordInput.fill('password')
    await adminLoginPage.signInButton.click()
    await expect(adminMainPage.logoutButton).toBeVisible()

    // Lets the test be re-run against the same server without reseeding.
    await adminMainPage.goto()
    await adminProducts.card(PRODUCT).link.click()
    await adminProducts.item.editLink.click()
    await adminProducts.form.inventoryInput.fill('0')
    await adminProducts.form.saveButton.click()
    await expect(adminProducts.item.outOfStock).toBeVisible()
  })

  await test.step('Log in as standard user and open the out-of-stock item', async () => {
    await loginPage.goto()
    await loginPage.emailInput.fill('alice@example.com')
    await loginPage.passwordInput.fill('password')
    await loginPage.signInButton.click()
    await expect(mainPage.logoutButton).toBeVisible()

    await mainPage.goto()
    await products.card(PRODUCT).link.click()
    await expect(item.title).toHaveText(PRODUCT)
    await expect(item.outOfStock, { message: `${PRODUCT} should be out of stock` }).toBeVisible()
  })

  await test.step('Subscribe to the back-in-stock email', async () => {
    await item.subscribeEmail.fill(subscriberEmail)
    await item.subscribeButton.click()
    await expect(mainPage.notice).toHaveText('You are now subscribed.')
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
    // The email is sent in the background, so reload until it arrives.
    await expect(async () => {
      await letterOpener.refreshButton.click()
      await expect(letterOpener.letter(subscriberEmail)).toBeVisible({ timeout: 1_000 })
    }).toPass({ timeout: 15_000 })

    await letterOpener.letter(subscriberEmail).click()
    await expect(letterOpener.mailBody.getByText(`${PRODUCT} is back in stock.`)).toBeVisible()
    await expect(letterOpener.mailBody.getByRole('link', { name: 'Unsubscribe' })).toBeVisible()
  })
})

import { test, expect } from '@playwright/test'
import { MainPage } from '../../pageObjects/mainPage'
import { LoginPage } from '../../pageObjects/loginPage'
import { MyOrders } from '../../pageObjects/myOrders'

// Only this test buys or restocks it, so tests stay independent.
const PRODUCT = 'Scarf'

// This test changes shared data (stock), so don't run its steps in parallel.
test.describe.configure({ mode: 'serial' })

test('standard user buys a product and sees it in their orders', async ({ page, browser }) => {
  // Standard user
  const mainPage = new MainPage(page)
  const loginPage = new LoginPage(page)
  const myOrders = new MyOrders(page)
  const { products } = mainPage
  const { item } = products

  // Admin, in a separate browser context, sets a known starting stock.
  const adminContext = await browser.newContext()
  const adminPage = await adminContext.newPage()
  const adminMainPage = new MainPage(adminPage)
  const adminLoginPage = new LoginPage(adminPage)
  const adminProducts = adminMainPage.products

  let ordersBefore = 0

  await test.step('Admin sets the starting stock to 10', async () => {
    await adminLoginPage.goto()
    await adminLoginPage.emailInput.fill('admin@example.com')
    await adminLoginPage.passwordInput.fill('password')
    await adminLoginPage.signInButton.click()
    await expect(adminMainPage.logoutButton).toBeVisible()

    await adminMainPage.goto()
    await adminProducts.card(PRODUCT).link.click()
    await adminProducts.item.editLink.click()
    await adminProducts.form.inventoryInput.fill('10')
    await adminProducts.form.saveButton.click()
    await expect(adminProducts.item.inStock).toHaveText('10 in stock')
    await adminContext.close()
  })

  await test.step('Log in as standard user and count existing orders', async () => {
    await loginPage.goto()
    await loginPage.emailInput.fill('alice@example.com')
    await loginPage.passwordInput.fill('password')
    await loginPage.signInButton.click()
    await expect(mainPage.logoutButton).toBeVisible()

    // Earlier runs may have left Scarf orders.
    await mainPage.myOrdersLink.click()
    await expect(myOrders.header).toBeVisible()
    ordersBefore = await myOrders.orders(PRODUCT).count()
  })

  await test.step('Buy 2 of the product', async () => {
    await mainPage.goto()
    await products.card(PRODUCT).link.click()
    await expect(item.inStock).toHaveText('10 in stock')

    await item.quantityInput.fill('2')
    await item.buyButton.click()
    await expect(mainPage.notice).toHaveText(`Purchased 2 × ${PRODUCT}.`)
    await expect(item.inStock, { message: 'Stock should drop by 2' }).toHaveText('8 in stock')
  })

  await test.step("Can't buy more than is in stock", async () => {
    await item.quantityInput.fill('9')
    await item.buyButton.click()

    // The browser blocks the form (max is the stock), so nothing is bought.
    expect(await item.quantityInput.evaluate((el: HTMLInputElement) => el.checkValidity())).toBe(
      false,
    )
    await expect(item.inStock).toHaveText('8 in stock')
  })

  await test.step('The order shows in My orders', async () => {
    await mainPage.myOrdersLink.click()
    await expect(myOrders.orders(PRODUCT)).toHaveCount(ordersBefore + 1)
    // Newest first.
    await expect(myOrders.orders(PRODUCT).first().getByRole('cell').nth(1)).toHaveText('2')
  })
})

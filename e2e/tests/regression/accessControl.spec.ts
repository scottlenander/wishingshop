import { test, expect } from '@playwright/test'
import { MainPage } from '../../pageObjects/mainPage'
import { LoginPage } from '../../pageObjects/loginPage'
import { AdminOrders } from '../../pageObjects/admin/orders'
import { AUTH_FILES } from '../../libs/auth'

// Typed straight into the address bar, since there are no links to them.
const ADMIN_PAGES = [
  '/admin/users',
  '/admin/orders',
  '/admin/subscribers',
  '/admin/announcements',
  '/admin/featured_products',
  '/admin/product_import/new',
  '/products/new',
]
const ACCOUNT_PAGES = ['/orders', '/addresses', '/subscriptions', '/checkout']

test.describe('a standard user', () => {
  // Read-only: this account only tries pages and changes nothing.
  test.use({ storageState: AUTH_FILES.access })

  test('is turned away from admin pages', async ({ page }) => {
    const mainPage = new MainPage(page)
    await mainPage.goto()
    await expect(mainPage.greeting).toBeVisible()
    await expect(mainPage.usersLink, 'no admin links in the nav').toHaveCount(0)

    for (const path of ADMIN_PAGES) {
      await test.step(path, async () => {
        await page.goto(path)
        await expect(page).toHaveURL('/')
        await expect(mainPage.alert).toHaveText("You're not authorized to do that.")
      })
    }
  })

  test("can't open another customer's order", async ({ page, browser }) => {
    // Find a real order number belonging to someone else.
    const adminContext = await browser.newContext({ storageState: AUTH_FILES.admin })
    const orders = new AdminOrders(await adminContext.newPage())
    await orders.goto()
    const number = await orders.numberOf(orders.ordersFor('reviewer1@example.com').first())
    await adminContext.close()
    expect(number).toMatch(/^WS-/)

    const response = await page.goto(`/orders/${number}`)
    expect(response?.status()).toBe(404)
  })
})

test('a visitor is asked to log in for account and admin pages', async ({ page }) => {
  const loginPage = new LoginPage(page)

  for (const path of [...ACCOUNT_PAGES, ...ADMIN_PAGES.filter((p) => p.startsWith('/admin'))]) {
    await test.step(path, async () => {
      await page.goto(path)
      await expect(page).toHaveURL('/session/new')
      await expect(loginPage.emailInput).toBeVisible()
    })
  }
})

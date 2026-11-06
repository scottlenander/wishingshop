import { test, expect, type Page } from '@playwright/test'
import { AxeBuilder } from '@axe-core/playwright'
import { MainPage } from '../../pageObjects/mainPage'
import { PRODUCTS, USERS } from '../../libs/constants'
import { AUTH_FILES } from '../../libs/auth'
import { TestData } from '../../libs/testData'

// Automated WCAG 2.2 AA checks (axe-core) on the main pages. These catch about
// a third of accessibility problems, such as missing labels, alt text, low
// contrast and broken ARIA. Keyboard and screen reader checks still need a person.
const WCAG_TAGS = ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa']

// Read-only: the product page with the most content (8 reviews).
const PRODUCT = PRODUCTS.T_SHIRT.name
// Read-only: added to the a11y account's cart so checkout can be scanned. Never bought.
const CART_PRODUCT = PRODUCTS.BASEBALL_CAP.name

// Scans the page as it is now. On failure, lists each problem and where it is.
async function expectNoViolations(page: Page) {
  const { violations } = await new AxeBuilder({ page }).withTags(WCAG_TAGS).analyze()
  const summary = violations.map(
    (v) =>
      `${v.id} (${v.impact}): ${v.help} at ${v.nodes.map((n) => n.target.join(' ')).join(', ')}`,
  )
  expect(summary, `accessibility problems on ${page.url()}`).toEqual([])
}

test.describe('visitor pages', () => {
  test('home, product, cart and sign-in pages', async ({ page }) => {
    const mainPage = new MainPage(page)
    // Pauses the carousel, so the scan sees a still page.
    await page.emulateMedia({ reducedMotion: 'reduce' })

    await test.step('Home', async () => {
      await mainPage.goto()
      await expectNoViolations(page)
    })
    await test.step('Product with reviews', async () => {
      await mainPage.products.open(PRODUCT)
      await expectNoViolations(page)
    })
    await test.step('Empty cart', async () => {
      await page.goto('/cart')
      await expectNoViolations(page)
    })
    await test.step('Sign in', async () => {
      await page.goto('/session/new')
      await expectNoViolations(page)
    })
    await test.step('Forgot password', async () => {
      await page.goto('/passwords/new')
      await expectNoViolations(page)
    })
    await test.step('Sign up', async () => {
      await page.goto('/sign_up')
      await expectNoViolations(page)
    })
  })
})

test.describe('signed-in pages', () => {
  test.use({ storageState: AUTH_FILES.a11y })

  test('cart, checkout and account pages', async ({ page, request }) => {
    const mainPage = new MainPage(page)
    const { item } = mainPage.products

    await test.step('Cart with an item', async () => {
      await new TestData(request).resetUser(USERS.a11y.email, ['cart'])
      await mainPage.products.open(CART_PRODUCT)
      await item.addToCartButton.click()
      await expect(mainPage.notice).toHaveText(`Added 1 × ${CART_PRODUCT} to your cart.`)
      await page.goto('/cart')
      await expectNoViolations(page)
    })
    await test.step('Checkout', async () => {
      await page.goto('/checkout')
      await expectNoViolations(page)
    })
    for (const path of [
      '/orders',
      '/addresses',
      '/subscriptions',
      '/account',
      '/account/edit',
      '/account/password/edit',
    ]) {
      await test.step(path, async () => {
        await page.goto(path)
        await expectNoViolations(page)
      })
    }
  })
})

test.describe('admin pages', () => {
  test.use({ storageState: AUTH_FILES.admin })

  test('every admin list and form', async ({ page }) => {
    const paths = [
      '/admin/users',
      '/admin/users/new',
      '/admin/orders',
      '/admin/subscribers',
      '/admin/announcements',
      '/admin/announcements/new',
      '/admin/featured_products',
      '/admin/featured_products/new',
      '/admin/product_import/new',
      '/products/new',
    ]
    for (const path of paths) {
      await test.step(path, async () => {
        await page.goto(path)
        await expectNoViolations(page)
      })
    }
  })
})

import { test, expect } from '@playwright/test'
import { MainPage } from '../../pageObjects/mainPage'
import { AUTH_FILES } from '../../libs/auth'
import { FeaturedProducts } from '../../pageObjects/admin/featuredProducts'
import { PRODUCTS } from '../../libs/constants'

const PRODUCT = PRODUCTS.LEATHER_BELT.name
// Read-only: only used to try an overlapping pick, which is refused.
const OTHER_PRODUCT = PRODUCTS.T_SHIRT.name

// This test changes shared data (the featured pick), so don't run its steps in parallel.
test.describe.configure({ mode: 'serial' })

// Starts signed in (see tests/auth.setup.ts).
test.use({ storageState: AUTH_FILES.admin })

test('admin features a product on the homepage, then removes it', async ({ page }) => {
  const mainPage = new MainPage(page)
  const featuredProducts = new FeaturedProducts(page)
  const { featured, products } = mainPage
  const { item } = products

  await test.step('Start signed in as admin', async () => {
    await mainPage.goto()
    await expect(mainPage.logoutButton).toBeVisible()
  })

  await test.step('Remove picks left by an earlier run', async () => {
    await mainPage.featuredLink.click()
    await expect(featuredProducts.header).toBeVisible()
    while ((await featuredProducts.removeButton(PRODUCT).count()) > 0) {
      await featuredProducts.remove(PRODUCT)
      await expect(mainPage.notice).toHaveText('Featured pick removed.')
    }
  })

  await test.step('Feature the product from its page', async () => {
    await mainPage.goto()
    await products.card(PRODUCT).link.click()
    await item.featureLink.click()

    // The shortcut pre-selects the product; keep the default window (now to 7 days).
    await expect(featuredProducts.selectedProduct).toHaveText(PRODUCT)
    await featuredProducts.saveButton.click()
    await expect(mainPage.notice).toHaveText(`${PRODUCT} will be featured.`)
    await expect(featuredProducts.showingNow).toContainText(PRODUCT)
  })

  await test.step('Homepage shows the admin pick', async () => {
    await mainPage.goto()
    await expect(featured.label).toBeVisible()
    await expect(featured.title).toHaveText(PRODUCT)
    await expect(featured.pickedNote).toBeVisible()
    await expect(featured.stockStatus).toBeVisible()

    await featured.link.click()
    await expect(item.title).toHaveText(PRODUCT)
  })

  await test.step('An overlapping pick is refused', async () => {
    await featuredProducts.goto()
    await featuredProducts.newLink.click()
    await featuredProducts.productSelect.selectOption({ label: OTHER_PRODUCT })
    await featuredProducts.saveButton.click()
    await expect(featuredProducts.error).toContainText(`Overlaps with ${PRODUCT}`)
  })

  await test.step('Remove the pick; the homepage goes back to the random pick', async () => {
    await featuredProducts.goto()
    await featuredProducts.remove(PRODUCT)
    await expect(mainPage.notice).toHaveText('Featured pick removed.')
    await expect(featuredProducts.showingNow).toContainText('Random today')

    await mainPage.goto()
    await expect(featured.title).toBeVisible()
    await expect(featured.pickedNote, {
      message: 'Random picks have no "Picked by our team" note',
    }).toBeHidden()
  })
})

import { test, expect } from '@playwright/test'
import { MainPage } from '../../pageObjects/mainPage'
import { PRODUCTS } from '../../libs/constants'
import { AUTH_FILES } from '../../libs/auth'

// Read-only: only its SKU is used, to try a duplicate.
const EXISTING_SKU = PRODUCTS.T_SHIRT.sku

// Starts signed in (see tests/auth.setup.ts).
test.use({ storageState: AUTH_FILES.admin })

test('admin creates, edits and deletes a product', async ({ page }) => {
  const mainPage = new MainPage(page)
  const { products } = mainPage
  const { item, form } = products
  // New every run, so it never clashes with a product left by an earlier run.
  const runId = Date.now()
  const name = `E2E Product ${runId}`
  const sku = `E2E-PRODUCT-${runId}`

  await test.step('A product needs a name', async () => {
    await mainPage.goto()
    await products.newProductLink.click()
    await form.skuInput.fill(sku)
    await form.saveButton.click()
    await expect(form.error).toHaveText("Name can't be blank")
  })

  await test.step('SKUs must be unique', async () => {
    await form.nameInput.fill(name)
    await form.skuInput.fill(EXISTING_SKU)
    await form.saveButton.click()
    await expect(form.error).toContainText('has already been taken')
  })

  await test.step('Create it with a price and stock', async () => {
    await form.nameInput.fill(name)
    await form.skuInput.fill(sku)
    await form.priceInput.fill('12.50')
    await form.inventoryInput.fill('7')
    await form.saveButton.click()

    await expect(item.title).toHaveText(name)
    await expect(item.price).toHaveText('$12.50')
    await expect(item.inStock).toHaveText('7 in stock')
  })

  await test.step("It's on the products page, not yet rated", async () => {
    await mainPage.goto()
    await expect(products.card(name).link).toBeVisible()
    await expect(products.card(name).notRated).toBeVisible()
  })

  await test.step('Edit the price and sell out', async () => {
    await products.open(name)
    await item.editLink.click()
    await form.priceInput.fill('15')
    await form.inventoryInput.fill('0')
    await form.saveButton.click()

    await expect(item.price).toHaveText('$15.00')
    await expect(item.outOfStock).toBeVisible()
  })

  await test.step('Delete it', async () => {
    await item.deleteProduct()
    await expect(products.header).toBeVisible()
    await expect(products.card(name).root).toHaveCount(0)
  })
})

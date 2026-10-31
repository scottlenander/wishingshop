import { test, expect } from '@playwright/test'
import { MainPage } from '../../pageObjects/mainPage'
import { LoginPage } from '../../pageObjects/loginPage'
import { ProductImport } from '../../pageObjects/admin/productImport'

// Existing product this test restocks. Only this test changes it.
const EXISTING = { name: 'Beanie', sku: 'BEANIE' }

// This test changes shared data (stock), so don't run its steps in parallel.
test.describe.configure({ mode: 'serial' })

test('admin bulk imports new products and updates stock', async ({ page }) => {
  const mainPage = new MainPage(page)
  const loginPage = new LoginPage(page)
  const productImport = new ProductImport(page)
  const { products } = mainPage
  const { item } = products

  // Unique per run, so the new product is always a "create".
  const runId = Date.now()
  const newProduct = { name: `Import Jacket ${runId}`, sku: `IMPORT-JACKET-${runId}` }
  let newStock = 0

  await test.step('Log in as admin', async () => {
    await loginPage.goto()
    await loginPage.emailInput.fill('admin@example.com')
    await loginPage.passwordInput.fill('password')
    await loginPage.signInButton.click()
    await expect(mainPage.logoutButton).toBeVisible()
  })

  await test.step('Pick a stock value different from the current one', async () => {
    // So the existing product is always an "update", even on a rerun.
    await mainPage.goto()
    await products.card(EXISTING.name).link.click()
    const status = (await item.stockStatus.textContent()) ?? ''
    const current = Number.parseInt(status, 10) || 0
    newStock = current === 33 ? 34 : 33
  })

  await test.step("A file with errors shows them and can't be applied", async () => {
    await mainPage.importLink.click()
    await expect(productImport.header).toBeVisible()

    await productImport.upload('sku,name,inventory_count\nBAD-ROW,Bad Row,lots\n')
    await expect(productImport.previewHeader).toBeVisible()
    await expect(productImport.summaryCount('with errors')).toHaveText('1 with errors')
    await expect(productImport.row(2)).toContainText('Stock must be a whole number')
    await expect(productImport.applyButton).toBeHidden()
  })

  await test.step('Upload a valid file and check the preview', async () => {
    await productImport.uploadAgainLink.click()
    await expect(productImport.header).toBeVisible()

    const csv = [
      'sku,name,description,inventory_count,image_url',
      `${EXISTING.sku},,,${newStock},`,
      `${newProduct.sku},${newProduct.name},Made by the import test.,12,`,
    ].join('\n')
    await productImport.upload(csv)

    await expect(productImport.summaryCount('to create')).toHaveText('1 to create')
    await expect(productImport.summaryCount('to update')).toHaveText('1 to update')
    await expect(productImport.summaryCount('with errors')).toHaveText('0 with errors')
    await expect(productImport.row(2)).toContainText(`Stock:`)
    await expect(productImport.row(3)).toContainText('Create')
  })

  await test.step('Apply the import', async () => {
    await productImport.applyButton.click()
    await expect(mainPage.notice).toHaveText('Import complete: 1 created, 1 updated, 0 unchanged.')
  })

  await test.step('New product exists and the existing stock changed', async () => {
    await products.card(newProduct.name).link.click()
    await expect(item.title).toHaveText(newProduct.name)
    await expect(item.inStock).toHaveText('12 in stock')

    await mainPage.goto()
    await products.card(EXISTING.name).link.click()
    await expect(item.inStock).toHaveText(`${newStock} in stock`)
  })
})

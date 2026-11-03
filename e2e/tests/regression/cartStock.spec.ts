import { test, expect } from '@playwright/test'
import { MainPage } from '../../pageObjects/mainPage'
import { Cart } from '../../pageObjects/cart'
import { PRODUCTS } from '../../libs/constants'
import { TestData } from '../../libs/testData'

// Only this test changes its stock.
const PRODUCT = PRODUCTS.CARDIGAN
// Read-only: seeded out of stock.
const OUT_OF_STOCK = PRODUCTS.CARGO_SHORTS.name

// Changes the Cardigan's stock, so the steps run in order.
test.describe.configure({ mode: 'serial' })

// A visitor: their cart lives in this browser only, so no account is shared.
test('cart quantities are kept within stock', async ({ page, request }) => {
  const mainPage = new MainPage(page)
  const cart = new Cart(page)
  const testData = new TestData(request)
  const { products } = mainPage
  const { item } = products

  await test.step('Start with 3 in stock', async () => {
    await testData.setStock(PRODUCT.sku, 3)
  })

  await test.step("The quantity box can't go above the stock", async () => {
    await products.open(PRODUCT.name)
    await expect(item.inStock).toHaveText('3 in stock')
    await expect(item.quantityInput).toHaveAttribute('max', '3')
  })

  await test.step('Adding more than is left is capped', async () => {
    await item.quantityInput.fill('2')
    await item.addToCartButton.click()
    await expect(mainPage.notice).toHaveText(`Added 2 × ${PRODUCT.name} to your cart.`)

    // 2 in the cart + 2 more = 4, but only 3 exist.
    await item.quantityInput.fill('2')
    await item.addToCartButton.click()
    await expect(mainPage.alert).toHaveText(`Only 3 ${PRODUCT.name} in stock, so your cart has 3.`)
    await expect(mainPage.cartCount).toHaveText('3')
  })

  await test.step("If stock drops below the cart, checkout waits until it's fixed", async () => {
    // As if other customers bought some in the meantime.
    await testData.setStock(PRODUCT.sku, 1)
    await cart.goto()
    await expect(cart.problems).toHaveText(
      `Only 1 ${PRODUCT.name} left. Lower the quantity to check out.`,
    )
    await expect(cart.checkoutButton).toBeDisabled()
  })

  await test.step('Lowering the quantity fixes it', async () => {
    await cart.setQuantity(PRODUCT.name, 1)
    await expect(mainPage.notice).toHaveText(`Updated ${PRODUCT.name}.`)
    await expect(cart.problems).toHaveCount(0)
    await expect(cart.checkoutButton).toHaveRole('link')
  })

  await test.step('Out-of-stock products have no Add to cart button', async () => {
    await products.open(OUT_OF_STOCK)
    await expect(item.outOfStock).toBeVisible()
    await expect(item.addToCartButton).toHaveCount(0)
    await expect(item.subscribeEmail).toBeVisible()
  })
})

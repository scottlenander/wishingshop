import { test, expect } from '@playwright/test'
import { MainPage } from '../../pageObjects/mainPage'
import { MyOrdersPage } from '../../pageObjects/myOrdersPage'
import { CartPage } from '../../pageObjects/cartPage'
import { CheckoutPage } from '../../pageObjects/checkoutPage'
import { OrderPage } from '../../pageObjects/orderPage'
import { PURCHASE_BILLING, PRODUCTS, TEST_CARDS, USERS, futureExpiry } from '../../libs/constants'
import { AUTH_FILES } from '../../libs/auth'
import { TestData } from '../../libs/testData'

// Only this test buys or restocks it, so tests stay independent. Seeded at $14.99.
const PRODUCT = PRODUCTS.SCARF

// This test changes shared data (stock, the purchase account's cart), so don't run its steps in parallel.
test.describe.configure({ mode: 'serial' })

// Starts signed in as the purchase account (see tests/auth.setup.ts).
test.use({ storageState: AUTH_FILES.purchase })

test('standard user checks out a cart and sees the order', async ({ page, request }) => {
  const mainPage = new MainPage(page)
  const cart = new CartPage(page)
  const checkout = new CheckoutPage(page)
  const orderPage = new OrderPage(page)
  const myOrders = new MyOrdersPage(page)
  const testData = new TestData(request)
  const { products } = mainPage
  const { item } = products

  let orderNumber = ''

  await test.step('Start with 10 in stock and an empty cart', async () => {
    await testData.setStock(PRODUCT.sku, 10)
    await testData.resetUser(USERS.purchase.email, ['cart'])
  })

  await test.step('Add 2 to the cart from the product page', async () => {
    await products.open(PRODUCT.name)
    await expect(item.price).toHaveText('$14.99')

    await item.quantityInput.fill('2')
    await item.addToCartButton.click()
    await expect(mainPage.notice).toHaveText(`Added 2 × ${PRODUCT.name} to your cart.`)
    await expect(mainPage.cartCount).toHaveText('2')
    // Adding to the cart doesn't take stock.
    await expect(item.inStock).toHaveText('10 in stock')
  })

  await test.step('Change the quantity in the cart', async () => {
    await mainPage.cartLink.click()
    await expect(cart.item(PRODUCT.name)).toBeVisible()

    await cart.setQuantity(PRODUCT.name, 3)
    await expect(mainPage.notice).toHaveText(`Updated ${PRODUCT.name}.`)
    await expect(cart.lineTotal(PRODUCT.name)).toHaveText('$44.97')
    await expect(cart.subtotal).toHaveText('$44.97')
    await expect(cart.shippingNote).toContainText('Add $5.03 more for free standard shipping')
  })

  await test.step('Check out with two-day shipping', async () => {
    await cart.checkoutButton.click()
    await expect(checkout.header).toBeVisible()
    await expect(checkout.summaryItems).toHaveText([/3 × Scarf\s*\$44\.97/])
    // The saved billing address is filled in, and orders ship there by default.
    await expect(checkout.billing.nameInput).toHaveValue(PURCHASE_BILLING.name)
    await expect(checkout.billing.line1Input).toHaveValue(PURCHASE_BILLING.line1)
    await expect(checkout.billing.zipInput).toHaveValue(PURCHASE_BILLING.zip)
    await expect(checkout.saveBillingCheckbox).not.toBeChecked()
    await expect(checkout.sameAsBillingCheckbox).toBeChecked()
    await expect(checkout.newShipping.root).toBeHidden()

    // The total updates as the shipping method changes.
    await expect(checkout.shippingCost).toHaveText('$4.99')
    await checkout.shippingOption('Two-day').check()
    await expect(checkout.shippingCost).toHaveText('$9.99')
    await expect(checkout.total).toHaveText('$54.96')

    await checkout.fillCard({ number: TEST_CARDS.success, expiry: futureExpiry() })
    await checkout.placeOrderButton.click()
  })

  await test.step('The order page shows what was bought', async () => {
    await expect(mainPage.notice).toContainText('Thanks! Your order WS-')
    orderNumber = await orderPage.number()

    await expect(orderPage.item(PRODUCT.name)).toContainText('$14.99')
    await expect(orderPage.item(PRODUCT.name)).toContainText('3')
    await expect(orderPage.total).toHaveText('$54.96')
    await expect(orderPage.payment).toHaveText('Visa ending 4242')
    await expect(orderPage.address).toContainText(PURCHASE_BILLING.line1)
    await expect(orderPage.billing).toHaveText('Same as shipping')
    await expect(mainPage.cartCount, { message: 'The cart is empty after checkout' }).toBeHidden()
  })

  await test.step('Stock dropped and the order is in My orders', async () => {
    await products.open(PRODUCT.name)
    await expect(item.inStock, { message: 'Stock should drop by 3' }).toHaveText('7 in stock')

    await mainPage.myOrdersLink.click()
    await expect(myOrders.header).toBeVisible()
    const row = myOrders.order(orderNumber)
    await expect(row).toContainText(`3 × ${PRODUCT.name}`)
    await expect(row).toContainText('Two-day')
    await expect(row).toContainText('$54.96')
  })
})

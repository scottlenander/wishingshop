import { test, expect } from '@playwright/test'
import { MainPage } from '../../pageObjects/mainPage'
import { MyOrders } from '../../pageObjects/myOrders'
import { Cart } from '../../pageObjects/cart'
import { Checkout } from '../../pageObjects/checkout'
import { OrderPage } from '../../pageObjects/orderPage'
import { ALICE_BILLING, PRODUCTS, TEST_CARDS, futureExpiry } from '../../libs/constants'
import { AUTH_FILES } from '../../libs/auth'

// Only this test buys or restocks it, so tests stay independent. Seeded at $14.99.
const PRODUCT = PRODUCTS.SCARF.name

// This test changes shared data (stock, Alice's cart), so don't run its steps in parallel.
test.describe.configure({ mode: 'serial' })

// Starts signed in as Alice; the admin context uses the saved admin session
// (see tests/auth.setup.ts).
test.use({ storageState: AUTH_FILES.alice })

test('standard user checks out a cart and sees the order', async ({ page, browser }) => {
  const mainPage = new MainPage(page)
  const cart = new Cart(page)
  const checkout = new Checkout(page)
  const orderPage = new OrderPage(page)
  const myOrders = new MyOrders(page)
  const { products } = mainPage
  const { item } = products

  // Admin, in a separate browser context, sets a known starting stock.
  const adminContext = await browser.newContext({ storageState: AUTH_FILES.admin })
  const adminPage = await adminContext.newPage()
  const adminMainPage = new MainPage(adminPage)
  const adminProducts = adminMainPage.products

  let orderNumber = ''

  await test.step('Admin sets the starting stock to 10', async () => {
    await adminMainPage.goto()
    await adminProducts.card(PRODUCT).link.click()
    await adminProducts.item.editLink.click()
    await adminProducts.form.inventoryInput.fill('10')
    await adminProducts.form.saveButton.click()
    await expect(adminProducts.item.inStock).toHaveText('10 in stock')
    await adminContext.close()
  })

  await test.step('Start with an empty cart', async () => {
    // Earlier runs may have left items in Alice's cart.
    await cart.empty()
  })

  await test.step('Add 2 to the cart from the product page', async () => {
    await mainPage.goto()
    await products.card(PRODUCT).link.click()
    await expect(item.price).toHaveText('$14.99')

    await item.quantityInput.fill('2')
    await item.addToCartButton.click()
    await expect(mainPage.notice).toHaveText(`Added 2 × ${PRODUCT} to your cart.`)
    await expect(mainPage.cartCount).toHaveText('2')
    // Adding to the cart doesn't take stock.
    await expect(item.inStock).toHaveText('10 in stock')
  })

  await test.step('Change the quantity in the cart', async () => {
    await mainPage.cartLink.click()
    await expect(cart.item(PRODUCT)).toBeVisible()

    await cart.setQuantity(PRODUCT, 3)
    await expect(mainPage.notice).toHaveText(`Updated ${PRODUCT}.`)
    await expect(cart.lineTotal(PRODUCT)).toHaveText('$44.97')
    await expect(cart.subtotal).toHaveText('$44.97')
    await expect(cart.shippingNote).toContainText('Add $5.03 more for free standard shipping')
  })

  await test.step('Check out with two-day shipping', async () => {
    await cart.checkoutButton.click()
    await expect(checkout.header).toBeVisible()
    await expect(checkout.summaryItems).toHaveText([/3 × Scarf\s*\$44\.97/])
    // Alice's saved billing address is filled in, and orders ship there by default.
    await expect(checkout.billing.nameInput).toHaveValue(ALICE_BILLING.name)
    await expect(checkout.billing.line1Input).toHaveValue(ALICE_BILLING.line1)
    await expect(checkout.billing.zipInput).toHaveValue(ALICE_BILLING.zip)
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

    await expect(orderPage.item(PRODUCT)).toContainText('$14.99')
    await expect(orderPage.item(PRODUCT)).toContainText('3')
    await expect(orderPage.total).toHaveText('$54.96')
    await expect(orderPage.payment).toHaveText('Visa ending 4242')
    await expect(orderPage.address).toContainText(ALICE_BILLING.line1)
    await expect(orderPage.billing).toHaveText('Same as shipping')
    await expect(mainPage.cartCount, { message: 'The cart is empty after checkout' }).toBeHidden()
  })

  await test.step('Stock dropped and the order is in My orders', async () => {
    await mainPage.goto()
    await products.card(PRODUCT).link.click()
    await expect(item.inStock, { message: 'Stock should drop by 3' }).toHaveText('7 in stock')

    await mainPage.myOrdersLink.click()
    await expect(myOrders.header).toBeVisible()
    const row = myOrders.order(orderNumber)
    await expect(row).toContainText(`3 × ${PRODUCT}`)
    await expect(row).toContainText('Two-day')
    await expect(row).toContainText('$54.96')
  })
})

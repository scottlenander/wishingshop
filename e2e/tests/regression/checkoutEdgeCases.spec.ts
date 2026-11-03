import { test, expect } from '@playwright/test'
import { MainPage } from '../../pageObjects/mainPage'
import { LoginPage } from '../../pageObjects/loginPage'
import { Cart } from '../../pageObjects/cart'
import { Checkout } from '../../pageObjects/checkout'
import { MyAddresses } from '../../pageObjects/myAddresses'
import { OrderPage } from '../../pageObjects/orderPage'
import {
  PRODUCTS,
  TEST_ADDRESS,
  TEST_CARDS,
  TEST_WORK_ADDRESS,
  USERS,
  futureExpiry,
} from '../../libs/constants'
import { AUTH_FILES } from '../../libs/auth'
import { TestData } from '../../libs/testData'

const CUSTOMER = USERS.checkout

// All tests here use the checkout account's cart and addresses, so they run one after the other.
test.describe.configure({ mode: 'serial' })

test.describe('as a signed-in customer', () => {
  test.use({ storageState: AUTH_FILES.checkout })

  test('a declined card places no order and saves nothing', async ({ page, request }) => {
    const PRODUCT = PRODUCTS.CHINOS.name
    const mainPage = new MainPage(page)
    const cart = new Cart(page)
    const checkout = new Checkout(page)
    const myAddresses = new MyAddresses(page)
    const { products } = mainPage
    const { item } = products
    let stockBefore = ''

    await test.step('Start with no saved addresses and an empty cart', async () => {
      await new TestData(request).resetUser(CUSTOMER.email, ['cart', 'addresses'])
    })

    await test.step('Add 1 to the cart', async () => {
      await products.open(PRODUCT)
      stockBefore = (await item.inStock.textContent()) ?? ''
      await item.addToCartButton.click()
      await expect(mainPage.notice).toHaveText(`Added 1 × ${PRODUCT} to your cart.`)
    })

    await test.step('Pay with the decline card', async () => {
      await mainPage.cartLink.click()
      await cart.checkoutButton.click()
      await checkout.billing.fill(TEST_ADDRESS)
      // On by default when nothing is saved yet.
      await expect(checkout.saveBillingCheckbox).toBeChecked()
      await checkout.fillCard({ number: TEST_CARDS.declined, expiry: futureExpiry() })
      await checkout.placeOrderButton.click()

      await expect(checkout.errors).toContainText('Your card was declined.')
      // The addresses and expiry are kept, so only the card number and CVC need typing again.
      await expect(checkout.billing.line1Input).toHaveValue(TEST_ADDRESS.line1)
      await expect(checkout.cardExpiryInput).toHaveValue(futureExpiry())
      // The full card number and CVC are never sent back to the browser.
      await expect(checkout.cardNumberInput).toHaveValue('')
      await expect(checkout.cardCvcInput).toHaveValue('')
      await expect(checkout.cardAgainNote).toHaveText(
        'For your security, enter your card number and security code again.',
      )
    })

    await test.step('A wrong expiry is marked, and kept for fixing', async () => {
      await checkout.fillCard({ number: TEST_CARDS.declined, expiry: '13/30' })
      await checkout.placeOrderButton.click()

      await expect(checkout.errors).toContainText('Expiry (MM/YY) must look like MM/YY')
      await expect(checkout.fieldError(checkout.cardExpiryInput)).toBeVisible()
      await expect(checkout.cardExpiryInput).toHaveValue('13/30')
      await expect(checkout.cardNumberInput).toHaveValue('')
    })

    await test.step('The expiry adds the slash while typing', async () => {
      await checkout.cardExpiryInput.clear()
      await checkout.cardExpiryInput.pressSequentially('12')
      await expect(checkout.cardExpiryInput).toHaveValue('12/')
      await checkout.cardExpiryInput.pressSequentially('30')
      await expect(checkout.cardExpiryInput).toHaveValue('12/30')

      // Deleting doesn't put the slash back: "12/30" -> "12/3" -> "12".
      await checkout.cardExpiryInput.press('Backspace')
      await expect(checkout.cardExpiryInput).toHaveValue('12/3')
      await checkout.cardExpiryInput.press('Backspace')
      await expect(checkout.cardExpiryInput).toHaveValue('12')

      // A first digit above 1 is a month.
      await checkout.cardExpiryInput.clear()
      await checkout.cardExpiryInput.pressSequentially('4')
      await expect(checkout.cardExpiryInput).toHaveValue('04/')
    })

    await test.step('Nothing changed: stock, cart, saved addresses', async () => {
      await products.open(PRODUCT)
      await expect(item.inStock).toHaveText(stockBefore)

      await myAddresses.goto()
      await expect(myAddresses.noBillingMessage).toBeVisible()

      await mainPage.cartLink.click()
      await expect(cart.item(PRODUCT)).toBeVisible()
      await cart.empty()
    })
  })

  test('saves billing and a nicknamed shipping address at checkout', async ({ page, request }) => {
    const PRODUCT = PRODUCTS.LINEN_PANTS.name
    const NICKNAME = 'Work'
    const mainPage = new MainPage(page)
    const cart = new Cart(page)
    const checkout = new Checkout(page)
    const orderPage = new OrderPage(page)
    const myAddresses = new MyAddresses(page)
    const { products } = mainPage
    const { item } = products

    await test.step('Start with stock (every run buys one), no saved addresses and an empty cart', async () => {
      const testData = new TestData(request)
      await testData.setStock(PRODUCTS.LINEN_PANTS.sku, 10)
      await testData.resetUser(CUSTOMER.email, ['cart', 'addresses'])
    })

    await test.step('Check out to a new shipping address and save both', async () => {
      await products.open(PRODUCT)
      await item.addToCartButton.click()
      await expect(mainPage.notice).toHaveText(`Added 1 × ${PRODUCT} to your cart.`)
      await mainPage.cartLink.click()
      await cart.checkoutButton.click()

      // Nothing saved: the name is filled in and saving is offered.
      await expect(checkout.billing.nameInput).toHaveValue(
        `${CUSTOMER.firstName} ${CUSTOMER.lastName}`,
      )
      await expect(checkout.billing.line1Input).toHaveValue('')
      await expect(checkout.saveBillingCheckbox).toBeChecked()
      await checkout.billing.fill(TEST_ADDRESS)

      // Not the same as billing: the shipping form appears; the nickname only when saving.
      await expect(checkout.newShipping.root).toBeHidden()
      await checkout.sameAsBillingCheckbox.uncheck()
      await expect(checkout.newShipping.root).toBeVisible()
      await expect(checkout.nicknameInput).toBeHidden()
      await checkout.shipToNewAddress(TEST_WORK_ADDRESS, NICKNAME)

      await checkout.fillCard({ number: TEST_CARDS.success, expiry: futureExpiry() })
      await checkout.placeOrderButton.click()
      await expect(mainPage.notice).toContainText('Thanks! Your order WS-')
    })

    await test.step('The order ships to the new address and bills the other', async () => {
      await expect(orderPage.address).toContainText(TEST_WORK_ADDRESS.line1)
      await expect(orderPage.billing).toContainText(TEST_ADDRESS.line1)
    })

    await test.step('Both addresses are saved', async () => {
      await mainPage.myAddressesLink.click()
      await expect(myAddresses.billing).toContainText(TEST_ADDRESS.line1)
      await expect(myAddresses.shipping(NICKNAME)).toContainText(TEST_WORK_ADDRESS.line1)
    })

    await test.step('Next checkout fills billing and offers the saved shipping address', async () => {
      await products.open(PRODUCT)
      await item.addToCartButton.click()
      // Wait for the add to finish, or checkout may still see an empty cart.
      await expect(mainPage.notice).toHaveText(`Added 1 × ${PRODUCT} to your cart.`)
      await checkout.goto()

      await expect(checkout.billing.line1Input).toHaveValue(TEST_ADDRESS.line1)
      await expect(checkout.saveBillingCheckbox).not.toBeChecked()
      await checkout.sameAsBillingCheckbox.uncheck()
      await expect(checkout.savedShipping(NICKNAME)).toBeChecked()
      // A saved address is picked, so the new-address form stays hidden.
      await expect(checkout.newShipping.root).toBeHidden()
      await checkout.newAddressRadio.check()
      await expect(checkout.newShipping.root).toBeVisible()
    })

    // Through the UI, so removing cart items and deleting addresses stay tested.
    await test.step('Clean up', async () => {
      await cart.empty()
      await myAddresses.deleteAll()
    })
  })
})

test('a visitor cart is kept through logging in at checkout', async ({ browser, request }) => {
  // A fresh browser with no saved session: a visitor.
  const context = await browser.newContext()
  const page = await context.newPage()
  const PRODUCT = PRODUCTS.SWEATPANTS.name
  const mainPage = new MainPage(page)
  const loginPage = new LoginPage(page)
  const cart = new Cart(page)
  const checkout = new Checkout(page)
  const testData = new TestData(request)
  const { products } = mainPage
  const { item } = products

  await test.step("Start with the customer's saved cart empty", async () => {
    // Otherwise items left from an earlier run would be merged in at login.
    await testData.resetUser(CUSTOMER.email, ['cart'])
  })

  await test.step('Add to the cart as a visitor', async () => {
    await mainPage.goto()
    await expect(mainPage.loginLink).toBeVisible()
    await products.card(PRODUCT).link.click()
    await item.addToCartButton.click()
    await expect(mainPage.notice).toHaveText(`Added 1 × ${PRODUCT} to your cart.`)
    await expect(mainPage.cartCount).toHaveText('1')
  })

  await test.step('Checkout asks the visitor to log in', async () => {
    await mainPage.cartLink.click()
    await cart.checkoutButton.click()
    await expect(loginPage.emailInput).toBeVisible()

    await loginPage.emailInput.fill(CUSTOMER.email)
    await loginPage.passwordInput.fill(CUSTOMER.password)
    await loginPage.signInButton.click()
  })

  await test.step('After logging in, checkout has the item', async () => {
    await expect(checkout.header).toBeVisible()
    await expect(checkout.summaryItems.filter({ hasText: `1 × ${PRODUCT}` })).toHaveCount(1)
    await expect(mainPage.greeting).toHaveText(`Hi, ${CUSTOMER.firstName}!`)
  })

  await test.step("Clean up the customer's cart", async () => {
    await testData.resetUser(CUSTOMER.email, ['cart'])
    await context.close()
  })
})

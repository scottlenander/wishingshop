import { expect, type Locator, type Page } from '@playwright/test'

type Address = { name?: string; line1: string; city: string; state: string; zip: string }

// One set of address inputs inside a fieldset (billing, or new shipping).
export class AddressFields {
  readonly root: Locator
  readonly nameInput: Locator
  readonly line1Input: Locator
  readonly line2Input: Locator
  readonly cityInput: Locator
  readonly stateInput: Locator
  readonly zipInput: Locator

  constructor(root: Locator) {
    this.root = root
    this.nameInput = root.getByLabel('Full name')
    this.line1Input = root.getByLabel('Address', { exact: true })
    this.line2Input = root.getByLabel('Apartment, suite, etc. (optional)')
    this.cityInput = root.getByLabel('City')
    this.stateInput = root.getByLabel('State')
    this.zipInput = root.getByLabel('ZIP code')
  }

  async fill(address: Address) {
    if (address.name) await this.nameInput.fill(address.name)
    await this.line1Input.fill(address.line1)
    await this.cityInput.fill(address.city)
    await this.stateInput.fill(address.state)
    await this.zipInput.fill(address.zip)
  }
}

// Checkout page (/checkout): billing and shipping addresses, shipping method,
// payment, summary.
export class CheckoutPage {
  readonly page: Page
  readonly header: Locator
  readonly errors: Locator

  // Billing address: filled from the saved one if there is one (editable).
  readonly billing: AddressFields
  // "Save as my billing address" (nothing saved yet) or "Update my saved billing address".
  readonly saveBillingCheckbox: Locator

  // Shipping address
  readonly sameAsBillingCheckbox: Locator
  readonly newAddressRadio: Locator
  readonly newShipping: AddressFields
  readonly saveShippingCheckbox: Locator
  readonly nicknameInput: Locator

  // Payment
  readonly cardNameInput: Locator
  readonly cardNumberInput: Locator
  readonly cardExpiryInput: Locator
  readonly cardCvcInput: Locator
  readonly cardAgainNote: Locator

  // Summary
  readonly summaryItems: Locator
  readonly shippingCost: Locator
  readonly total: Locator
  readonly placeOrderButton: Locator

  constructor(page: Page) {
    this.page = page
    this.header = page.getByRole('heading', { name: 'Checkout' })
    this.errors = page.getByTestId('checkout-errors')

    this.billing = new AddressFields(page.getByRole('group', { name: 'Billing address' }))
    this.saveBillingCheckbox = page.getByRole('checkbox', {
      name: /(Save as my|Update my saved) billing address/,
    })

    this.sameAsBillingCheckbox = page.getByRole('checkbox', { name: 'Ship to my billing address' })
    this.newAddressRadio = page.getByRole('radio', { name: 'New address' })
    this.newShipping = new AddressFields(page.getByRole('group', { name: 'New shipping address' }))
    this.saveShippingCheckbox = page.getByRole('checkbox', {
      name: 'Save this address for next time',
    })
    this.nicknameInput = page.getByLabel('Nickname')

    this.cardNameInput = page.getByLabel('Name on card')
    this.cardNumberInput = page.getByLabel('Card number')
    this.cardExpiryInput = page.getByLabel('Expiry (MM/YY)')
    this.cardCvcInput = page.getByLabel('Security code (CVC)')
    // After an error: the card number and CVC are cleared and must be typed again.
    this.cardAgainNote = page.getByTestId('card-again-note')

    this.summaryItems = page.getByTestId('summary-item')
    this.shippingCost = page.getByTestId('checkout-shipping-cost')
    this.total = page.getByTestId('checkout-total')
    this.placeOrderButton = page.getByRole('button', { name: 'Place order' })
  }

  async goto() {
    await this.page.goto('/checkout')
  }

  // Radio for "Standard", "Two-day" or "Same-day".
  shippingOption(label: 'Standard' | 'Two-day' | 'Same-day'): Locator {
    return this.page.getByRole('radio', { name: new RegExp(`^${label}\\b`) })
  }

  // An input Rails marked invalid (wrapped in .field_with_errors), or nothing.
  fieldError(input: Locator): Locator {
    return this.page.getByTestId('field-error').filter({ has: input })
  }

  // Radio for a saved shipping address, by nickname.
  savedShipping(nickname: string): Locator {
    return this.page
      .getByRole('radiogroup', { name: 'Saved shipping addresses' })
      .getByRole('radio', { name: new RegExp(`^${nickname}\\b`) })
  }

  // Ship somewhere other than the billing address, using a new address.
  async shipToNewAddress(address: Address, saveAs?: string) {
    await this.sameAsBillingCheckbox.uncheck()
    if (await this.newAddressRadio.isVisible()) await this.newAddressRadio.check()
    await expect(this.newShipping.root).toBeVisible()
    await this.newShipping.fill(address)
    if (saveAs) {
      await this.saveShippingCheckbox.check()
      await this.nicknameInput.fill(saveAs)
    }
  }

  async fillCard(card: { number: string; expiry: string; cvc?: string }) {
    await this.cardNumberInput.fill(card.number)
    await this.cardExpiryInput.fill(card.expiry)
    await this.cardCvcInput.fill(card.cvc ?? '123')
  }
}

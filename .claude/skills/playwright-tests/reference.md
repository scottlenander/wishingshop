# Templates and recipes

Copy these shapes. Imports use relative paths from the spec (`'../../pageObjects/...'`). Prettier settings are in `e2e/.prettierrc.json`: no semicolons, single quotes, 100-character lines.

## Spec

```ts
import { test, expect } from '@playwright/test'
import { MainPage } from '../../pageObjects/mainPage'
import { CartPage } from '../../pageObjects/cartPage'
import { AUTH_FILES } from '../../libs/auth'
import { PRODUCTS, USERS } from '../../libs/constants'
import { TestData } from '../../libs/testData'

// Changes its stock; claimed in libs/constants.ts.
const PRODUCT = PRODUCTS.CHINOS.name
const CUSTOMER = USERS.checkout

test.use({ storageState: AUTH_FILES.checkout })

test('a customer changes the quantity in their cart', async ({ page, request }) => {
  const mainPage = new MainPage(page)
  const cart = new CartPage(page)
  const { products } = mainPage
  const { item } = products

  await test.step('Start with an empty cart', async () => {
    await new TestData(request).resetUser(CUSTOMER.email, ['cart'])
  })

  await test.step('Add 1 to the cart', async () => {
    await products.open(PRODUCT)
    await item.addToCartButton.click()
    await expect(mainPage.notice).toHaveText(`Added 1 × ${PRODUCT} to your cart.`)
  })

  await test.step('Change it to 2', async () => {
    await cart.goto()
    await cart.setQuantity(PRODUCT, 2)
    await expect(cart.quantityInput(PRODUCT)).toHaveValue('2')
  })

  await test.step('Clean up', async () => {
    await cart.empty()
  })
})
```

Variations:

- **Several tests sharing an account or product:** wrap them in `test.describe('as a signed-in customer', () => { test.use({ storageState: ... }); ... })` and add `test.describe.configure({ mode: 'serial' })` at the top with a comment.
- **A visitor inside a signed-in file:** `const context = await browser.newContext(); const page = await context.newPage()`, and `await context.close()` in the last step.
- **A second user (e.g. admin) mid-test:**
  ```ts
  await test.step('Admin restocks the item', async () => {
    // In a separate browser, so the customer stays logged in.
    const adminContext = await browser.newContext({ storageState: AUTH_FILES.admin })
    const adminProducts = new MainPage(await adminContext.newPage()).products
    // ...
    await adminContext.close()
  })
  ```
- **Smoke tests** sign in through `LoginPage` instead of `storageState`.

## Page object

```ts
import type { Locator, Page } from '@playwright/test'

// My wishlist (/wishlist). Signed in only.
export class WishlistPage {
  readonly page: Page
  readonly header: Locator
  readonly items: Locator
  readonly emptyMessage: Locator

  constructor(page: Page) {
    this.page = page
    this.header = page.getByRole('heading', { name: 'My wishlist' })
    this.items = page.getByTestId('wishlist-item')
    this.emptyMessage = page.getByText('Your wishlist is empty.')
  }

  async goto() {
    await this.page.goto('/wishlist')
  }

  // One row, found by product name.
  item(productName: string): Locator {
    return this.items.filter({
      has: this.page.getByRole('link', { name: productName, exact: true }),
    })
  }

  removeButton(productName: string): Locator {
    return this.page.getByRole('button', { name: `Remove ${productName}` })
  }
}
```

- File `pageObjects/wishlistPage.ts`, class `WishlistPage`. Admin pages go in `pageObjects/admin/` without the suffix (`AdminWishlists`).
- Import `expect` too only if a method waits on its own action.
- If the page is reached from the header, add the nav link to `MainPage` (scoped to `nav`, `exact: true`, with a `// signed in` or `// admins only` note).

## Component

A part of a page with its own root, exposed as a field of the page (or of another component):

```ts
import type { Locator, Page } from '@playwright/test'

// Size picker on the product page (products/show).
export class SizePicker {
  readonly root: Locator
  readonly options: Locator
  readonly selected: Locator

  constructor(page: Page) {
    this.root = page.getByRole('radiogroup', { name: 'Size' })
    this.options = this.root.getByRole('radio')
    this.selected = this.root.getByRole('radio', { checked: true })
  }

  option(size: string): Locator {
    return this.root.getByRole('radio', { name: size, exact: true })
  }
}
```

For repeated items found by name, wrap a `root: Locator` (see `IndexCard` in `components/products.ts`) and return it from a method: `card(name): IndexCard`.

Forms get their own class with a `root` (`getByTestId('<thing>-form')`), an `error` (`this.root.getByTestId('form-error')`), one field per input via `getByLabel`, and the submit button.

## Adding a test id to a view

```erb
<li data-testid="wishlist-item">...</li>
<%= tag.div class: "wishlist__total", data: { testid: "wishlist-total" } do %>...<% end %>
```

Keep the existing classes; the id is added beside them. Ids stay in production.

## Adding a test account

When a new spec changes a standard user's data:

1. `db/seeds.rb`: add `{ email_address: "e2e-<name>@example.com", first_name: ..., last_name: ... }` to `E2E_USERS`. Seed any starting data (a past order, an address) in the `if ENV["E2E"] == "1"` block below it.
2. `e2e/libs/constants.ts`: add the account to `USERS` with the same details and `usedBy: ['regression/<spec>.spec.ts']`.
3. `e2e/libs/auth.ts`: add `<name>: authFile('<name>')` to `AUTH_FILES`.
4. `e2e/tests/auth.setup.ts`: add `{ role: '<name>', user: USERS.<name>, file: AUTH_FILES.<name> }` to `ACCOUNTS`.
5. Restart the e2e server so the account is seeded.

Accounts a test deactivates (like `deactivate`) don't get a saved session; the spec signs in itself.

## Adding a TestData shortcut

1. Add an action to `app/controllers/e2e/data_controller.rb` and its route in the `namespace :e2e` block of `config/routes.rb`. Keep it limited to e2e accounts or test-made records.
2. Add a method to `TestData` in `libs/testData.ts` that calls `this.post('<path>', {...})`.
3. Make sure some test does the same change through the UI, and add a row to the shortcut table in the README.

## Adding a page to the accessibility scan

In `tests/accessibility/pages.spec.ts`, add a step to the matching describe (visitor, signed-in or admin):

```ts
await test.step('My wishlist', async () => {
  await page.goto('/wishlist')
  await expectNoViolations(page)
})
```

---
name: playwright-tests
description: Write, change or debug the Playwright end-to-end tests in e2e/ for this Rails store. Use when asked to add a browser/e2e/Playwright test, cover a new feature or page in e2e, update tests after a UI change, add or change a page object or component, or work out why a Playwright test fails or is flaky (locally or in the GitHub "Playwright (Chromium)" check).
---

# Playwright tests (e2e/)

The suite tests the store in a real browser, the way a person uses it. New and changed tests must look like the existing ones: **steps**, **page objects**, and **components** for the smaller parts of a page. Read one or two nearby specs before writing anything; they are the style guide.

All commands run from `e2e/` unless noted.

## Layout

| Path | What's there |
|---|---|
| `tests/smoke/` | Quick end-to-end paths for a standard user and an admin. They sign in through the form. |
| `tests/regression/` | One spec per feature or flow (`purchase`, `checkoutEdgeCases`, `account`, `categories`...). They start signed in from a saved session. |
| `tests/accessibility/pages.spec.ts` | axe WCAG 2.2 AA scans. Add a step here when you add a new page. |
| `tests/auth.setup.ts` | Signs in once per test account and saves the session. |
| `pageObjects/*Page.ts` | One class per page, named `<Name>Page` in `<name>Page.ts` (`CartPage` in `cartPage.ts`). |
| `pageObjects/components/` | Parts of a page used in more than one place (`Products`, `Reviews`, `Carousel`, `Featured`). No `Page` suffix. |
| `pageObjects/admin/` | Admin pages (`AdminUsers` in `users.ts`). No `Page` suffix. |
| `libs/constants.ts` | Seeded `PRODUCTS` (with who uses them), `USERS`, test cards, addresses, `futureExpiry()`. |
| `libs/auth.ts` | `AUTH_FILES`: one saved session per account. |
| `libs/testData.ts` | `TestData`: set-up and clean-up shortcuts through `/e2e/...` routes. |

The app side: views in `app/views/`, e2e-only routes in `app/controllers/e2e/data_controller.rb`, test accounts in `E2E_USERS` in `db/seeds.rb`.

## Writing or changing a test

1. **Read the feature first.** Open the view(s) and controller under test so locators match the real markup and wording. Read the closest existing spec and its page objects.
2. **Pick the data.**
   - Products: in `PRODUCTS` (`libs/constants.ts`), check `usedBy` and `changes`. Reading a product can be shared. **If the test changes a product** (stock, orders, subscriptions, reviews, edits), claim one nobody else changes: add your spec to its `usedBy`, set `changes: true`, and write a one-line comment saying what happens to it.
   - Accounts: a spec that changes a standard user's cart, addresses, subscriptions or reviews **gets its own account**. Never share one between specs. See "Adding a test account" in [reference.md](reference.md). Admin is shared.
3. **Add or extend page objects** before writing the spec. A spec should not contain raw locators except for a one-off check, such as `products.category('Tops').getByRole('link', ...)` built from page object pieces.
4. **Write the spec** with `test.step`s (template in [reference.md](reference.md)).
5. **Run the checks** in "Verify" below.
6. **Update the docs** if you added a spec or changed what's covered: the "What's tested" list in the README's Testing section, and the shortcut table there if you added a `TestData` method.

## Rules for specs

- **Steps:** every test body is a sequence of `await test.step('Plain sentence', async () => { ... })`. Name steps after what a person does or sees: `'Add 1 to the cart'`, `'Nothing changed: stock, cart, saved addresses'`. Set-up is its own first step (`'Start with an empty cart'`); clean-up its own last step (`'Clean up'`).
- **Test names** describe behaviour: `'a declined card places no order and saves nothing'`.
- **Page objects at the top** of the test: `const mainPage = new MainPage(page)`, `const cart = new CartPage(page)`. Variables drop the `Page` suffix except `mainPage`, `loginPage`, `orderPage`. Destructure deep components: `const { products } = mainPage; const { item } = products`.
- **Constants at the top of the file** with a comment on how the data is used: `// Read-only: just looks at ...` or `// Seeded out of stock.`
- **Assertions** use web-first `expect(locator).toHaveText/toBeVisible/toHaveCount/...`. Never `waitForTimeout`, never `isVisible()` inside an `expect(true)`.
- **Messages on unclear assertions:** if it isn't obvious from the line what is being checked or why, add a `message` saying what is expected, as a "should" sentence:
  ```ts
  await expect(products.card(name).notRated, {
    message: `The product ${name} should not have a rating`,
  }).toBeVisible()
  await expect(mainPage.usersLink, {
    message: 'Users link should be visible for admin users.',
  }).toBeVisible()
  ```
  Skip it when the line already says it, e.g. `expect(item.title).toHaveText(PRODUCT)` or `expect(mainPage.notice).toHaveText('You are now subscribed.')`. Typical cases that need one: `toBeHidden`/`not.` checks, `toHaveCount(0)`, `toBeVisible()` on a locator whose name doesn't say why it matters, and checks that depend on who is signed in.
- **Wait for the result before moving on.** After a click that submits, assert the flash (`mainPage.notice`) or the new heading before navigating away, or the next page may load before the server finishes. Comment why when it isn't obvious.
- **Set-up and clean-up:** use `TestData` (`resetUser`, `setStock`...) to reach a known start. Anything the test is *about* must go through the UI. Each `TestData` shortcut must also be done through the UI in at least one test.
- **Re-runnable:** a test must pass when run twice against the same server without reseeding. Reset what it changes at the start, not only at the end. Count existing emails before expecting "one more".
- **Signed in:** `test.use({ storageState: AUTH_FILES.<account> })` at file or describe level. A second user in the same test: `browser.newContext({ storageState: AUTH_FILES.admin })`, closed at the end of its step. A visitor: `browser.newContext()` with no storage state.
- **Shared state in a file** (same account or product across tests): `test.describe.configure({ mode: 'serial' })` with a comment saying why.
- **Comments** are short and say *why*: what the data is for, why a wait is needed, what markup a locator relies on.

## Rules for page objects and components

- **Class shape:** `readonly` `Locator` fields assigned in the constructor, a `goto()` for pages with a URL, methods for parameterised locators (`item(name)`, `removeButton(name)`) and for multi-step actions used by several tests (`setQuantity`, `empty`, `deactivate`). Template in [reference.md](reference.md).
- **One class per page.** A part used on more than one page, or big enough to stand alone (a form, a card, a review list), becomes a component class in `components/`, exposed as a field: `mainPage.products.item.reviews`. Repeated items found by a name (a card, a row) get a small class wrapping a `root: Locator` (see `IndexCard` in `components/products.ts`).
- **Scope locators** to a `root` when the page has several similar areas (`this.root.getByRole('button', { name: 'Delete' })`), and to the nav for header links.
- **A comment on the class** says which page or URL it covers and anything unusual (who can see it, what's hidden). Comment fields whose text varies: `// "Create Product" on new, "Update Product" on edit.`
- **Only page-level actions belong in page objects.** Assertions about what a test expects stay in the spec; a method may use `expect` only to wait for its own action to finish (as `CartPage.empty()` does).
- **Dialogs:** `this.page.once('dialog', (dialog) => void dialog.accept())` right before the click.

## Finding elements (in this order)

1. **`getByRole`** with the accessible name, `exact: true` when the name could match more (`getByRole('link', { name: 'Orders', exact: true })`). Regex for names that vary: `{ name: /^Cart, / }`.
2. **`getByLabel`** for form fields, **`getByPlaceholder`** only when there's no label.
3. **`getByText`** for fixed messages (`'Your cart is empty.'`).
4. **`getByTestId`** when none of the above fits (a row, a card, a total, an error box). Add the id to the view: `data-testid="cart-item"` or `data: { testid: "cart-item" }` in a Rails helper. Kebab-case, named after what it *is*, not how it looks. Repeated items share one id and are narrowed with `.filter({ has: ... })` or `.filter({ hasText: ... })`. Shared ids already in use: `form-error` (error line on any form), `field-error` (invalid field wrapper), `flash-notice`, `flash-alert`.
5. **Never CSS classes or page structure** (`.cart__item`, `tbody tr`, `td.first()`). `npm run lint` rejects class selectors in `.locator(...)`. Allowed `locator()` uses: ARIA attributes (`[aria-roledescription="slide"]`), ids that are also link targets (`#write-review`), `label[for=...]`, `option:checked`, and the letter_opener gem's markup (with an eslint-disable comment).

If an element has no good accessible name, prefer fixing the view (a label, an `aria-label`) over adding a test id; that helps real users too. Then add an accessibility scan step if the page is new.

## Verify

```bash
cd e2e
npm run lint && npm run typecheck && npm run format:check   # npm run format fixes formatting
npx playwright test tests/regression/<spec>.spec.ts          # the spec you touched
npx playwright test tests/regression/<spec>.spec.ts --repeat-each=3   # catches re-run and timing problems
npm test                                                      # the whole suite before finishing
```

Playwright starts `bin/e2e-server` itself (fresh seeded `storage/e2e.sqlite3` on port 3100), or reuses one already running locally **without reseeding**. If you changed seeds, views, routes or Ruby code, stop the old server first so the run gets fresh data and code. If you also changed Rails code, run `bin/rails test` from the repo root.

**Stop the server when done**, by port (Puma renames its process, so don't search by name):

```bash
lsof -ti tcp:3100 | xargs kill; sleep 1; lsof -ti tcp:3100 || echo "port 3100 free"
```

## Debugging a failure

Work out *which* kind of failure it is before changing anything. Don't "fix" a test by loosening its assertion or adding a timeout without knowing the cause.

1. **Reproduce on its own:** `npx playwright test tests/regression/<spec>.spec.ts -g "<test name>"`. Add `--headed` to watch, `--debug` to step through, or `npm run test:ui`.
2. **Read the evidence:** `npm run report` opens the HTML report with the failing step, screenshot, video and trace. A trace on its own: `npx playwright show-trace test-results/<folder>/trace.zip`. In CI, download the `playwright-report` artifact from the failed run and open it the same way. The GitHub annotation shows the failing line.
3. **Match the symptom:**

| Symptom | Likely cause | Fix |
|---|---|---|
| Locator not found / times out; the screenshot shows the element with different text | The view's wording or markup changed | Update the page object (one place), not each spec |
| Strict mode violation: "resolved to 2 elements" | The locator matches more than intended (e.g. a product card named like a nav link) | Scope it to a `root`/nav, add `exact: true`, or filter |
| Passes alone, fails in the full run | Two specs share an account or product, or a test depends on another's leftovers | Give the spec its own account/product; reset at the start |
| Passes first run, fails the second | The test doesn't reset what it changes, or counts absolute numbers | Reset in the first step; compare to a count taken before |
| Fails only in CI | One worker and retries in CI (`CI=1`), slower machine, fresh database every run | Run locally with `CI=1 npx playwright test ...` on a fresh server; look for a missing wait after a submit |
| Value typed before the page loaded; a logout then login loses the session | Moving on before the last action finished | Assert the heading/notice/link of the next state before the next action |
| 404 from `TestData` ("Is the server running with E2E=1?") | A server started some other way is on port 3100 | Stop it; let Playwright start `bin/e2e-server` |
| Signed in as the wrong person, or redirected to login | Saved session from before a reseed | `auth.setup.ts` re-checks sessions; delete `playwright/.auth/*.json` if it persists |
| Too many login attempts | Server not started with the raised `LOGIN_RATE_LIMIT` | Restart through `bin/e2e-server` |
| axe failure | The page broke an accessibility rule; the message names the rule and element | Fix the view, not the test |

4. **Decide whether the test or the app is wrong.** If the app misbehaves, say so and fix the app (or report it) rather than changing the test to match the bug.
5. **After the fix,** rerun the spec with `--repeat-each=3`, then the full suite, then stop the server.

## Before you finish

- [ ] Steps in every test; page objects and components hold the locators.
- [ ] Assertions that aren't obvious have a "should" `message`.
- [ ] New locators follow the order above; any new `data-testid` is in the view.
- [ ] Products and accounts claimed in `libs/constants.ts` (and seeds/auth files for a new account).
- [ ] Lint, typecheck, format check and the touched specs pass, twice in a row.
- [ ] README "What's tested" updated if coverage changed.
- [ ] Port 3100 is free.

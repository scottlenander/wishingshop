# WishingShop

A fake shopping website built for development and testing practice. Based on the [Ruby on Rails tutorial](https://guides.rubyonrails.org/getting_started.html).

## Features

- **Feature 1** — Short description of the first key feature
- **Feature 2** — Short description of the second key feature
- **Feature 3** — Short description of the third key feature
- **Feature 4** — Short description of the fourth key feature

## Quick Start

### Prerequisites

- Ruby >= 3.2
- Rails >= 8.1
- [libvips](https://www.libvips.org/install.html)

### Installation

Create DB first time:

```bash
bin/rails db:create
```

### Basic Usage

```bash
bin/rails server
```

## Test Data

Seed the database with test users, 20 clothing products and a few subscribers (development and test only; seeds are skipped in production):

```bash
bin/rails db:migrate
bin/rails db:seed    # safe to run more than once
bin/rails db:reset   # start over: drop, recreate and seed
```

### Accounts

All accounts use the password `password`.

| Email | Name | Role |
|---|---|---|
| `admin@example.com` | Admin Manager | Admin |
| `alice@example.com` | Alice Cooper | User (saved billing address: 18 Elm Street, Springfield, IL 62704) |
| `bob@example.com` | Bob Builder | User |

Admins can create, edit and delete products (including stock), and have six extra pages in the header:

- **Announcements** (`/admin/announcements`): slides for the homepage carousel (new products, sales, news), each with optional linked products, an image, and start/end times.
- **Featured** (`/admin/featured_products`): pick the homepage featured product for a time window. Picks can't overlap. Admins can also click **Feature this product** on any product page.
- **Import** (`/admin/product_import/new`): bulk add or update products from a CSV. See [Bulk import](#bulk-import).
- **Orders** (`/admin/orders`): every purchase by every user.
- **Users** (`/admin/users`): add, edit and deactivate standard users. Admin accounts aren't listed. See [Deactivated users](#deactivated-users).
- **Subscribers** (`/admin/subscribers`): add, edit, move and remove back-in-stock subscribers.

Signed-in users (standard or admin) can:

- **Shop:** see [Shopping and checkout](#shopping-and-checkout).
- **Subscribe** to an out-of-stock product with **Notify me**, which uses their account email. They can unsubscribe from the product page or **My subscriptions** (`/subscriptions`).

Visitors can browse products, add them to a cart, and subscribe to out-of-stock items by typing an email.

### Deactivated users

Users are never deleted. **Deactivate** on the admin Users page:

- logs them out and stops them logging in, and stops their back-in-stock emails;
- keeps their orders (marked "Deactivated" on the admin Orders page), reviews and email address. The email can't be used for a new user.

To undo it, an admin clicks **Restore** in the page's Deactivated list, or the user resets their password. Logging in with the right password tells them to use **Forgot password?**, and the reset email says it will reactivate the account.

### Shopping and checkout

Every product has a price (seeded from $14.99 to $119.99).

1. **Cart:** on a product page, choose a quantity and click **Add to cart**. The **Cart** link in the header shows how many items are in it. On the cart page you can change quantities or remove items. Visitors have a cart too, kept in their browser's session cookie (not the database), up to 50 different products.
2. **Checkout:** enter a billing address, choose where to ship, pick a shipping method and pay. Visitors are asked to log in first, and their cart is kept. Addresses are US only.
   - **Billing address:** filled in from your saved one if you have one, and you can still edit it. Tick **Save as my billing address** (or **Update my saved billing address**) to keep it.
   - **Shipping address:** **Ship to my billing address** is ticked by default. Untick it to pick a saved shipping address or enter a new one, which you can save with a nickname (e.g. "Work").
3. **My addresses** (`/addresses`): view, add, edit and delete your billing address and saved shipping addresses.
4. **My orders** (`/orders`): every order, with its items, prices, billing and shipping addresses, shipping and payment, kept as they were when ordered.

| Shipping | Price | Delivery |
|---|---|---|
| Standard | $4.99, **free on orders of $50 or more** | 3–5 business days |
| Two-day | $9.99 | 2 business days |
| Same-day | $19.99 | Today, order by 2pm |

Payment is fake (no money is taken). Only the card type and last 4 digits are saved, and card details are filtered out of the logs.

| Test card | Result |
|---|---|
| `4242 4242 4242 4242` | Paid |
| `4000 0000 0000 0002` | Declined |

Use any future expiry (e.g. `12/30`) and any 3-digit code.

### Reviews

Product pages show reviews: a 1 to 5 star rating and some text.

- **Who can review:** only signed-in users who have ordered the product, once each. Reviews show a "Verified purchase" badge and the reviewer's first name and last initial.
- **Editing:** authors can edit or delete their own review; admins can delete any review.
- **Product cards** on the products page show the average stars and review count (e.g. 4.0 (8)), or "Not yet rated", for everyone, signed in or not.
- **On the page:** an average with a 5-to-1 star breakdown, the 3 newest reviews, and **Show more reviews**, which loads the next 10 without leaving the page.
- **Seeded:** 8 reviewer accounts (`reviewer1@example.com` … `reviewer8@example.com`, password `password`) with past orders. The **T-Shirt** has 8 reviews (average 4.0) and the **Denim Jacket** 3.
  - Alice has bought the **Graphic Tee** but not reviewed it, so she can write one.
  - Bob hasn't bought it, so he sees why he can't.

### Homepage

The top of the products page has an **announcements carousel** and a **featured product** (side by side on desktop, stacked on phones).

- **Carousel:** shows live announcements. Seeded with three: "New: Rain Coat", "20% off scarves this week" and "Free shipping over $50". It moves every 6 seconds, pauses on hover, focus or the Pause button, and doesn't move at all for visitors who prefer reduced motion. Sales are text only: they don't change prices.
- **Featured product:** the admin's active pick, marked "Picked by our team". Without one, a random in-stock product is shown, the same for everyone all day and changing each day (UTC).

### Products

20 clothing items with cartoon images and generated descriptions. Stock is between 1 and 50, except for 3 items that are out of stock: **Hoodie**, **Puffer Vest** and **Cargo Shorts**.

Images are in `db/seeds/images/`. To change them, edit `script/generate_seed_images.rb` and run `ruby script/generate_seed_images.rb` (needs ImageMagick and libvips).

### Subscribers and emails

Each out-of-stock product has one subscriber:

| Product | Subscriber |
|---|---|
| Hoodie | `subscriber1@example.com` |
| Puffer Vest | `subscriber2@example.com` |
| Cargo Shorts | `subscriber3@example.com` |

In development, emails aren't sent. They're saved and can be read at [localhost:3000/letter_opener](http://localhost:3000/letter_opener). To test the back-in-stock email:

1. Log in as `admin@example.com`.
2. Edit one of the out-of-stock products and set its inventory above 0.
3. Open `/letter_opener` to see the email.

## Bulk import

Admins can create and update many products at once from a CSV file. Rows are matched by **SKU**: a known SKU updates that product, and a new SKU creates one.

```csv
sku,name,description,price,inventory_count,image_url
HOODIE,,,,25,
WINTER-COAT,Winter Coat,A warm wool coat.,129.00,30,https://example.com/coat.png
```

| Column | Meaning |
|---|---|
| `sku` | Required. Letters, numbers and dashes. Existing products have SKUs made from their names (e.g. `T-SHIRT`). |
| `name` | Required for new products. |
| `description` | Plain text. |
| `price` | Dollars, like `19.99`. A product priced 0 isn't for sale. |
| `inventory_count` | Sets the stock to this number (it doesn't add to it). |
| `image_url` | Optional http/https image, up to 5 MB. Downloaded and attached. |

For existing products, blank cells keep the current value. Files can be up to 1 MB and 1,000 rows. Restocking an out-of-stock product sends the usual back-in-stock emails.

**In the app:** go to **Import**, upload the file, check the preview, then click **Apply import**. Nothing is saved until you apply, and a file with any errors can't be applied. The page also has a blank template and an export of current products to edit and upload again.

**From the command line** (handy in development):

```bash
bin/rails "products:import[db/seeds/products_import_example.csv]"           # preview only
bin/rails "products:import[db/seeds/products_import_example.csv]" APPLY=1   # save
```

An example file is in [db/seeds/products_import_example.csv](db/seeds/products_import_example.csv).

## Testing

### Rails tests

Fast tests for models, controllers and mailers in `test/`, using fixture data from `test/fixtures/`. Use them to check app logic such as validations, admin-only access and back-in-stock emails.

```bash
bin/rails test                                   # all tests
bin/rails test test/models/user_test.rb          # one file
```

### Playwright end-to-end tests

Browser tests in `e2e/` that click through the app the way a user would. They're separate from Rails and only run when called.

- `tests/smoke/`: quick checks of the main standard-user and admin flows.
- `tests/regression/`: longer flows, such as:
  - **Shopping:** checking out a cart, a declined card, a visitor's cart surviving login, cart quantities kept within stock.
  - **Reviews:** writing, editing and deleting a review; an admin deleting someone else's.
  - **Stock emails:** subscribing to an out-of-stock item (signed in, or as a visitor by email), receiving the email, and unsubscribing from My subscriptions or the email's link.
  - **Admin:** creating, editing and deleting products; adding and editing users; the Orders page; bulk import; featuring a product; announcements.
  - **Accounts:** deactivating and restoring a user, and reactivating by password reset; standard users and visitors kept out of admin and account pages.
- `tests/accessibility/`: automated WCAG 2.2 AA scans (axe-core) of the visitor, signed-in and admin pages. A failure lists each problem and the element it's on. These catch common problems (labels, alt text, contrast, ARIA), not everything; keyboard and screen reader checks still need a person.
- `pageObjects/`: shared locators for each page, used by all tests.
- `tests/auth.setup.ts`: signs in once per run as admin and each test account, and saves the sessions (git-ignored, in `playwright/.auth/`). Regression tests start already signed in with `test.use({ storageState: AUTH_FILES.admin })`; the smoke tests still sign in through the form, as admin and Alice.
- **One account per spec:** each regression spec that changes a standard user's data (cart, addresses, subscriptions, reviews) has its own account, such as `e2e-purchase@example.com` or `e2e-checkout@example.com`. So specs running in parallel never share data. They're listed in `E2E_USERS` in `db/seeds.rb` and `USERS` in `e2e/libs/constants.ts`, and only seeded on the e2e server. Admin is shared, since admin specs only change the products they claim.
- `libs/testData.ts`: quick set-up and clean-up through test-only routes (`/e2e/...`), e.g. emptying a cart, setting stock or removing a test's leftover announcements. The routes are never drawn in production, and return 404 unless the server runs with `E2E=1`, which only `bin/e2e-server` sets. Every change they make is still done through the UI in at least one test:

  | Shortcut | Also tested in the UI by |
  |---|---|
  | Empty cart | `checkoutEdgeCases` (Remove buttons) |
  | Delete addresses | `checkoutEdgeCases` (My addresses) |
  | Remove subscriptions | `outOfStock` (My subscriptions) |
  | Delete reviews | `reviews` |
  | Set stock | `outOfStock` (admin product form) |
  | Delete announcements | `announcements` |
  | Remove featured picks | `featuredProduct` |
  | Deactivate or restore a user | `deactivateUser` (admin Users page) |

Playwright starts the app automatically with `bin/e2e-server`, which resets and seeds a separate database (`storage/e2e.sqlite3`) on port 3100. Your development data isn't touched. It also raises the login rate limit (`LOGIN_RATE_LIMIT`, normally 10 per 3 minutes), so test runs aren't locked out.

When a test fails, its trace, screenshot and video are kept in the HTML report (`npm run report`), so the failure can be replayed step by step.

**In CI:** `.github/workflows/e2e.yml` runs lint, typecheck, the format check and the whole suite on Chromium for every pull request, as the **Playwright (Chromium)** check. A newer push to the same pull request cancels the older run. If it fails, the report, traces and screenshots are attached to the run as `playwright-report` for 7 days. In CI, tests use one worker and retry up to twice, and a test that only passes on a retry is reported as flaky. To try it locally the same way: `CI=1 npx playwright test`.

First-time setup:

```bash
cd e2e
npm install
npx playwright install
```

Run from `e2e/`:

```bash
npm test                # run all tests
npm run test:headed     # watch the browser
npm run test:ui         # Playwright's interactive UI
npm run report          # open the last HTML report
npm run lint && npm run typecheck && npm run format:check
```

## License

Distributed under the MIT License. See `LICENSE` for more information.

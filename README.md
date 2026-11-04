# WishingShop

A practice online clothing store, built to try out development and testing. It started from the [Ruby on Rails tutorial](https://guides.rubyonrails.org/getting_started.html) and has grown into a small but complete shop, with seeded data and a browser test suite. Payments are fake: no money is ever taken.

## Features

- **Categories:** products are grouped into Tops, Bottoms, Accessories, Jackets and Hats on the products page.
- **Shopping and checkout:** a cart for everyone (visitors too), checkout with saved billing and shipping addresses, three shipping speeds, a fake card payment, and order history.
- **Reviews:** customers who bought a product can rate it 1 to 5 stars and write a review. Products show their average rating, and reviews can be sorted and filtered by stars.
- **Back-in-stock emails:** anyone can ask to be emailed when an out-of-stock product returns. Restocking sends the emails automatically.
- **Homepage:** a carousel of announcements (sales, new products, news) and a featured product, either picked by an admin or chosen at random each day.
- **Admin tools:** manage products and stock, bulk import from CSV, announcements, featured picks, orders, users and subscribers.
- **Accounts:** sign in, password reset by email, and soft-deleted users: admins deactivate users instead of deleting them, so their orders and reviews are kept.
- **Accessibility:** proper labels, alt text and keyboard support, checked automatically against WCAG 2.2 AA.
- **Tests:** fast Rails tests, plus Playwright browser tests that run on every pull request.

## Quick start

### Prerequisites

- Ruby 3.4 (the exact version is in `.ruby-version`). Bundler installs Rails 8.1.
- [libvips](https://www.libvips.org/install.html), for product image thumbnails.
- Node 26, only for the Playwright tests.

### Set up and run

```bash
bin/setup
```

This installs the gems, creates the database, fills it with [test data](#test-data), and starts the app at [localhost:3000](http://localhost:3000). Next time, start the app with `bin/rails server` (or `bin/dev`).

Log in as `admin@example.com` or `alice@example.com`, both with the password `password`.

## Test data

The seeds add test accounts, 20 clothing products, reviews, announcements and back-in-stock subscribers. They only run in development and test, never in production.

```bash
bin/rails db:seed    # add the test data; safe to run more than once
bin/rails db:reset   # start over: drop, recreate and seed
```

### Accounts

All accounts use the password `password`.

| Email | Name | Role |
|---|---|---|
| `admin@example.com` | Admin Manager | Admin |
| `alice@example.com` | Alice Cooper | User. Has a saved billing address (18 Elm Street, Springfield, IL 62704), and has bought the Graphic Tee but not reviewed it |
| `bob@example.com` | Bob Builder | User. Hasn't bought anything |
| `reviewer1@example.com` … `reviewer8@example.com` | Random names | Users who wrote the seeded reviews |

### Products, reviews and subscribers

- **Products:** 20 clothing items with cartoon images and generated descriptions, priced from $14.99 to $119.99. Stock is between 1 and 50, except for 3 items that are out of stock. Each is in one category:

  | Category | Products |
  |---|---|
  | Tops | T-Shirt, Graphic Tee, Polo Shirt, Oxford Shirt, Flannel Shirt, Hoodie, Wool Sweater, Cardigan |
  | Bottoms | Chinos, Sweatpants, Linen Pants, Cargo Shorts |
  | Accessories | Scarf, Leather Belt |
  | Jackets | Denim Jacket, Bomber Jacket, Rain Coat, Puffer Vest |
  | Hats | Beanie, Baseball Cap |

- **Reviews:** the **T-Shirt** has 8 reviews (average 4.0), enough to try **Show more**, sorting and filtering. The **Denim Jacket** has 3.
- **Subscribers:** each out-of-stock product has one, to try the back-in-stock email:

  | Product (out of stock) | Subscriber |
  |---|---|
  | Hoodie | `subscriber1@example.com` |
  | Puffer Vest | `subscriber2@example.com` |
  | Cargo Shorts | `subscriber3@example.com` |

- **Announcements:** three live slides: "New: Rain Coat", "20% off scarves this week" and "Free shipping over $50".

Product images are in `db/seeds/images/`. To change them, edit `script/generate_seed_images.rb` and run `ruby script/generate_seed_images.rb`, which needs ImageMagick and libvips.

### Test cards

| Card number | Result |
|---|---|
| `4242 4242 4242 4242` | Paid |
| `4000 0000 0000 0002` | Declined |

Use any future expiry (e.g. `12/30`) and any 3-digit code.

### Emails in development

Emails aren't sent in development. They're saved, and you can read them at [localhost:3000/letter_opener](http://localhost:3000/letter_opener).

## Shopping

### Homepage

The top of the products page has an **announcements carousel** and a **featured product**: side by side on desktop, stacked on phones.

- **Carousel:** shows the live announcements. It moves every 6 seconds and pauses on hover, on focus, or with the Pause button. It doesn't move at all for visitors who prefer reduced motion. Sales announcements are text only: they don't change prices.
- **Featured product:** the admin's current pick, marked "Picked by our team". Without one, a random in-stock product is shown. It's the same for everyone all day and changes each day (UTC).
- **Categories:** below that, products are grouped into sections by category, in a fixed order (Tops, Bottoms, Accessories, Jackets, Hats), sorted by name within each. Empty categories aren't shown. A product's page shows its category above the name, linking back to that section.
- **Product cards** show each product's price and average rating, e.g. ★★★★☆ 4.0 (8), or "Not yet rated".

### Cart and checkout

1. **Cart:** on a product page, choose a quantity and click **Add to cart**. The **Cart** link in the header shows how many items are in it.
   - On the cart page you can change quantities or remove items.
   - Quantities are capped at the stock. If stock drops below what's in your cart, checkout waits until you lower the quantity.
   - Visitors have a cart too, kept in their browser's session cookie rather than the database, for up to 50 different products. It's moved into their account when they log in.
2. **Checkout:** enter a billing address, choose where to ship, pick a shipping method and pay. Visitors are asked to log in first, and their cart is kept. Addresses are US only.
   - **Billing address:** filled in from your saved one, if you have one, and you can still edit it. Tick **Save as my billing address** (or **Update my saved billing address**) to keep it.
   - **Shipping address:** **Ship to my billing address** is ticked by default. Untick it to pick a saved shipping address, or to enter a new one, which you can save with a nickname (e.g. "Work").
3. **My orders** (`/orders`): every order, with its items, prices, billing and shipping addresses, shipping method and payment, as they were when ordered.
4. **My addresses** (`/addresses`): view, add, edit and delete your billing address and saved shipping addresses.

| Shipping | Price | Delivery |
|---|---|---|
| Standard | $4.99, **free on orders of $50 or more** | 3–5 business days |
| Two-day | $9.99 | 2 business days |
| Same-day | $19.99 | Today, if ordered by 2pm |

**Payment** is fake: no money is taken. Use the [test cards](#test-cards).
- **What's stored:** only the card type and last 4 digits are saved, and card details are filtered out of the logs.
- **After an error:** if checkout fails (e.g. a declined card), everything is kept except the card number and security code. Those are never sent back to the browser, so they must be entered again.
- **With a real payment provider:** the card fields should be the provider's hosted fields (e.g. Stripe Elements), so card details never reach this server.

### Reviews

- **Who can review:** signed-in users who have ordered the product, once each. Reviews show a "Verified purchase" badge and the reviewer's first name and last initial.
- **Editing:** authors can edit or delete their own review. Admins can delete any review.
- **On the product page:**
  - **Under the title:** the average and the number of reviews, linking down to the reviews.
  - **Reviews section:** a 5-to-1 star breakdown, the 3 newest reviews, and **Show more reviews**, which loads the next 10 without leaving the page.
  - **Sort** by Newest, Highest rated or Lowest rated. Click a star level in the breakdown (e.g. **5 stars**) to see only those reviews, and **Show all reviews** to go back.
  - **Sharing:** the sort and filter stay in the URL (e.g. `?sort=highest&stars=5`), so a filtered view can be shared, and **Show more** keeps them.

To try it: Alice can review the Graphic Tee, and Bob is shown why he can't.

### Back-in-stock emails

On an out-of-stock product:
- **Signed-in users:** click **Notify me**, which uses their account email. They can unsubscribe from the product page or from **My subscriptions** (`/subscriptions`).
- **Visitors:** type an email address.
- **Every email** has an **Unsubscribe** link.

To try it:
1. Log in as `admin@example.com`.
2. Edit an out-of-stock product (e.g. the Hoodie) and set its stock above 0.
3. Open [/letter_opener](http://localhost:3000/letter_opener) to see the email.

## Admin

Admins can create, edit and delete products, including their category, price and stock. Every product needs a category. The list is fixed in `Product::CATEGORY_LABELS` (`app/models/product.rb`); adding one is a one-line change there. A **Feature this product** button on each product page makes it the homepage featured pick. Six extra pages appear in the header:

| Page | What it's for |
|---|---|
| **Announcements** (`/admin/announcements`) | Slides for the homepage carousel (new products, sales, news), each with optional linked products, an image, and start and end times. |
| **Featured** (`/admin/featured_products`) | Pick the homepage featured product for a time window. Picks can't overlap. |
| **Import** (`/admin/product_import/new`) | Add or update many products at once from a CSV. See [Bulk import](#bulk-import). |
| **Orders** (`/admin/orders`) | Every order by every customer. |
| **Users** (`/admin/users`) | Add, edit, deactivate and restore standard users. Admin accounts aren't listed. See [Deactivated users](#deactivated-users). |
| **Subscribers** (`/admin/subscribers`) | Add, edit, move and remove back-in-stock subscribers. |

### Deactivated users

Users are never deleted. **Deactivate** on the Users page:
- **Stops them:** logs them out, stops them logging in, and stops their back-in-stock emails.
- **Keeps their data:** their orders (marked "Deactivated" on the Orders page), reviews and email address. The email can't be used for a new user.

**To undo it:** an admin clicks **Restore** in the Deactivated list, or the user resets their password. If they log in with the right password, they're told to use **Forgot password?**, and the reset email says it will reactivate the account.

### Bulk import

Create and update many products at once from a CSV file. Rows are matched by **SKU**: a known SKU updates that product, and a new SKU creates one.

```csv
sku,name,category,description,price,inventory_count,image_url
HOODIE,,,,,25,
WINTER-COAT,Winter Coat,Jackets,A warm wool coat.,129.00,30,https://example.com/coat.png
```

| Column | Meaning |
|---|---|
| `sku` | Required. Letters, numbers and dashes. Existing products have SKUs made from their names (e.g. `T-SHIRT`). |
| `name` | Required for new products. |
| `category` | Required for new products. One of Tops, Bottoms, Accessories, Jackets or Hats (any capitalization). |
| `description` | Plain text. |
| `price` | Dollars, like `19.99`. A product priced 0 isn't for sale. |
| `inventory_count` | Sets the stock to this number (it doesn't add to it). |
| `image_url` | Optional http/https image, up to 5 MB. Downloaded and attached. |

- **Blank cells** keep the current value for existing products.
- **Limits:** files can be up to 1 MB and 1,000 rows.
- **Restocking** an out-of-stock product sends the usual back-in-stock emails.

**In the app:**
1. Go to **Import** and upload the file.
2. Check the preview, then click **Apply import**.

Nothing is saved until you apply, and a file with any errors can't be applied. The page also has a blank template, and an export of the current products to edit and upload again.

**From the command line**, which is handy in development:

```bash
bin/rails "products:import[db/seeds/products_import_example.csv]"           # preview only
bin/rails "products:import[db/seeds/products_import_example.csv]" APPLY=1   # save
```

An example file is in [db/seeds/products_import_example.csv](db/seeds/products_import_example.csv).

## Testing

| Suite | What it checks | Run with |
|---|---|---|
| **Rails tests** (`test/`) | Models, controllers, helpers, mailers and multi-step flows, using fixture data. Fast. | `bin/rails test` |
| **Playwright** (`e2e/`) | The app in a real browser, the way a person uses it, including accessibility scans. | `npm test` in `e2e/` |

Code checks: `bin/rubocop` (style) and `bin/brakeman` (security).

### Rails tests

```bash
bin/rails test                            # all tests
bin/rails test test/models/user_test.rb   # one file
```

### Playwright end-to-end tests

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

Playwright starts the app itself with `bin/e2e-server`, which resets and seeds a separate database (`storage/e2e.sqlite3`) and serves it on port 3100. Your development data isn't touched.

When a test fails, its trace, screenshot and video are kept in the HTML report (`npm run report`), so you can replay the failure step by step.

**What's tested:**
- `tests/smoke/`: quick checks of the main standard-user and admin flows.
- `tests/regression/`: longer flows:
  - **Shopping:** checking out a cart, a declined card, a visitor's cart surviving login, and cart quantities kept within stock.
  - **Reviews:** writing, editing and deleting a review; sorting and filtering; an admin deleting someone else's review.
  - **Stock emails:** subscribing to an out-of-stock item (signed in, or as a visitor by email), receiving the email, and unsubscribing from My subscriptions or from the email's link.
  - **Browsing:** products grouped by category, and a product page linking back to its category.
  - **Admin:** creating, editing and deleting products; adding and editing users; the Orders page; bulk import; featuring a product; announcements.
  - **Accounts:** deactivating and restoring a user, and reactivating by password reset; standard users and visitors kept out of admin and account pages.
- `tests/accessibility/`: automated WCAG 2.2 AA scans (axe-core) of the visitor, signed-in and admin pages. A failure lists each problem and the element it's on.
  - **What they catch:** common problems such as labels, alt text, contrast and ARIA.
  - **What they don't:** keyboard and screen reader checks still need a person.

**How the suite is organized:**
- **Page objects** (`pageObjects/`): shared locators for each page, used by every test.
- **Saved logins** (`tests/auth.setup.ts`): signs in once per run as admin and as each test account, and saves the sessions in `playwright/.auth/` (git-ignored).
  - Regression tests start already signed in, with `test.use({ storageState: AUTH_FILES.admin })`.
  - The smoke tests still sign in through the form, as admin and Alice.
- **One account per spec:** each regression spec that changes a standard user's data (cart, addresses, subscriptions, reviews) has its own account, such as `e2e-purchase@example.com`. So specs running in parallel never share data.
  - These accounts are listed in `E2E_USERS` in `db/seeds.rb` and in `USERS` in `e2e/libs/constants.ts`, and they're only seeded on the e2e server.
  - Admin is shared, since admin specs only change the products they claim.
- **Product claims** (`libs/constants.ts`): lists which spec uses each seeded product. A spec that changes a product claims its own.
- **Test-data shortcuts** (`libs/testData.ts`): quick set-up and clean-up through test-only routes (`/e2e/...`), e.g. emptying a cart, setting stock, or removing a test's leftover announcements.
  - **Safety:** the routes are never drawn in production, and return 404 unless the server runs with `E2E=1`, which only `bin/e2e-server` sets.
  - **Still tested in the UI:** every change they make is also done through the UI in at least one test:

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

- **Login limit:** `bin/e2e-server` also raises the login rate limit (`LOGIN_RATE_LIMIT`, normally 10 per 3 minutes), so test runs aren't locked out.

### Continuous integration

GitHub Actions runs on every pull request:

- **`ci.yml`:** Rails tests, rubocop, and security scans of the code and dependencies. It also runs on pushes to `main`.
- **`e2e.yml`:** lint, typecheck, the format check, and the whole Playwright suite on Chromium, as the **Playwright (Chromium)** check.
  - **New pushes:** a newer push to the same pull request cancels the older run.
  - **Retries:** tests run on one worker and retry up to twice; a test that only passes on a retry is reported as flaky.
  - **Failures:** the report, traces and screenshots are attached to the run as `playwright-report` for 7 days.
  - **Running it locally the same way:** `CI=1 npx playwright test`.

Playwright only runs on Chromium for now. Firefox, Safari (WebKit) and mobile browsers are planned.

## License

Distributed under the MIT License. See `LICENSE` for more information.

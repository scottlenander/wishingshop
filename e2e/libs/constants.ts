// Seeded products (db/seeds.rb, reset for every run by bin/e2e-server).
//
// Tests that CHANGE a product (stock, subscriptions, orders) must each use their
// own product, so tests never interfere and can be re-run safely. Before using a
// product in a test, check `usedBy` here; claim a free one if you will change it.
//
// - seededStock: 'out' if the seed makes it out of stock, otherwise 'in' (1–50,
//   fixed by the seed but not worth asserting on).
// - usedBy: spec files that use it. `changes: true` means a test modifies it.

export type SeededProduct = {
  readonly name: string
  readonly sku: string
  readonly seededStock: 'in' | 'out'
  readonly changes: boolean
  readonly usedBy: readonly string[]
}

export const PRODUCTS = {
  BASEBALL_CAP: {
    name: 'Baseball Cap',
    sku: 'BASEBALL-CAP',
    seededStock: 'in',
    // Added to the a11y account's cart to scan checkout. Not bought.
    changes: false,
    usedBy: ['accessibility/pages.spec.ts'],
  },
  BEANIE: {
    name: 'Beanie',
    sku: 'BEANIE',
    seededStock: 'in',
    // Stock set to 20, then changed to 33 by CSV import.
    changes: true,
    usedBy: ['regression/bulkImport.spec.ts'],
  },
  BOMBER_JACKET: {
    name: 'Bomber Jacket',
    sku: 'BOMBER-JACKET',
    seededStock: 'in',
    changes: false,
    usedBy: [],
  },
  CARDIGAN: {
    name: 'Cardigan',
    sku: 'CARDIGAN',
    seededStock: 'in',
    // Stock set to 3, then 1, around a visitor's cart.
    changes: true,
    usedBy: ['regression/cartStock.spec.ts'],
  },
  CARGO_SHORTS: {
    name: 'Cargo Shorts',
    sku: 'CARGO-SHORTS',
    seededStock: 'out',
    // Read-only: out of stock, so no Add to cart button.
    changes: false,
    usedBy: ['regression/cartStock.spec.ts'],
  },
  CHINOS: {
    name: 'Chinos',
    sku: 'CHINOS',
    seededStock: 'in',
    // Added to the checkout account's cart; the declined payment leaves stock unchanged.
    changes: false,
    usedBy: ['regression/checkoutEdgeCases.spec.ts'],
  },
  DENIM_JACKET: {
    name: 'Denim Jacket',
    sku: 'DENIM-JACKET',
    seededStock: 'in',
    changes: false,
    usedBy: [],
  },
  FLANNEL_SHIRT: {
    name: 'Flannel Shirt',
    sku: 'FLANNEL-SHIRT',
    seededStock: 'in',
    // The review-moderation account reviews it; admin deletes the review.
    changes: true,
    usedBy: ['regression/reviewModeration.spec.ts'],
  },
  GRAPHIC_TEE: {
    name: 'Graphic Tee',
    sku: 'GRAPHIC-TEE',
    seededStock: 'in',
    // The reviews account has a seeded order of it: writes, edits and deletes a review.
    changes: true,
    usedBy: ['regression/reviews.spec.ts'],
  },
  HOODIE: {
    name: 'Hoodie',
    sku: 'HOODIE',
    seededStock: 'out',
    // Stock set to 0 then restocked; the out-of-stock account subscribes.
    changes: true,
    usedBy: ['regression/outOfStock.spec.ts'],
  },
  LEATHER_BELT: {
    name: 'Leather Belt',
    sku: 'LEATHER-BELT',
    seededStock: 'in',
    // Made the admin featured pick, then removed.
    changes: true,
    usedBy: ['regression/featuredProduct.spec.ts'],
  },
  LINEN_PANTS: {
    name: 'Linen Pants',
    sku: 'LINEN-PANTS',
    seededStock: 'in',
    // Stock set to 10, then the checkout account buys 1 while saving addresses.
    changes: true,
    usedBy: ['regression/checkoutEdgeCases.spec.ts'],
  },
  OXFORD_SHIRT: {
    name: 'Oxford Shirt',
    sku: 'OXFORD-SHIRT',
    seededStock: 'in',
    changes: false,
    usedBy: [],
  },
  POLO_SHIRT: {
    name: 'Polo Shirt',
    sku: 'POLO-SHIRT',
    seededStock: 'in',
    changes: false,
    usedBy: [],
  },
  PUFFER_VEST: {
    name: 'Puffer Vest',
    sku: 'PUFFER-VEST',
    seededStock: 'out',
    // Stock set to 0, a visitor subscribes, then restocked.
    changes: true,
    usedBy: ['regression/visitorSubscribe.spec.ts'],
  },
  RAIN_COAT: { name: 'Rain Coat', sku: 'RAIN-COAT', seededStock: 'in', changes: false, usedBy: [] },
  SCARF: {
    name: 'Scarf',
    sku: 'SCARF',
    seededStock: 'in',
    // Stock set to 10, then the purchase account checks out 3.
    changes: true,
    usedBy: ['regression/purchase.spec.ts'],
  },
  SWEATPANTS: {
    name: 'Sweatpants',
    sku: 'SWEATPANTS',
    seededStock: 'in',
    // Added to a visitor cart, which moves to the checkout account on login. Not bought.
    changes: false,
    usedBy: ['regression/checkoutEdgeCases.spec.ts'],
  },
  T_SHIRT: {
    name: 'T-Shirt',
    sku: 'T-SHIRT',
    seededStock: 'in',
    // Read-only, so it can be shared. Has the 8 seeded reviews.
    changes: false,
    usedBy: [
      'smoke/standardUserPath.spec.ts',
      'smoke/adminUserPath.spec.ts',
      'regression/reviews.spec.ts',
    ],
  },
  WOOL_SWEATER: {
    name: 'Wool Sweater',
    sku: 'WOOL-SWEATER',
    seededStock: 'in',
    // Read-only: no reviews, so its card says "Not yet rated".
    changes: false,
    usedBy: ['regression/reviews.spec.ts'],
  },
} as const satisfies Record<string, SeededProduct>

// Seeded accounts (db/seeds.rb). All use the same password.
//
// Each spec that changes a standard user's data (cart, addresses, subscriptions,
// reviews) has its own account, listed in E2E_USERS in db/seeds.rb, so specs
// running in parallel never touch each other's data. Add a new one there and
// here (plus AUTH_FILES and tests/auth.setup.ts) for a new spec, rather than
// sharing. Admin is shared: admin specs only change the products they claim.
type SeededUser = {
  readonly email: string
  readonly password: string
  readonly firstName: string
  readonly lastName: string
  readonly usedBy: readonly string[]
}

export const USERS = {
  admin: {
    email: 'admin@example.com',
    password: 'password',
    firstName: 'Admin',
    lastName: 'Manager',
    usedBy: [
      'smoke/adminUserPath.spec.ts',
      'regression/announcements.spec.ts',
      'regression/bulkImport.spec.ts',
      'regression/featuredProduct.spec.ts',
    ],
  },
  // Demo accounts, also used by the standard-user smoke test (read-only).
  alice: {
    email: 'alice@example.com',
    password: 'password',
    firstName: 'Alice',
    lastName: 'Cooper',
    usedBy: ['smoke/standardUserPath.spec.ts'],
  },
  bob: {
    email: 'bob@example.com',
    password: 'password',
    firstName: 'Bob',
    lastName: 'Builder',
    usedBy: [],
  },
  // Seeded only on the e2e server.
  purchase: {
    email: 'e2e-purchase@example.com',
    password: 'password',
    firstName: 'Pat',
    lastName: 'Purchase',
    usedBy: ['regression/purchase.spec.ts'],
  },
  outOfStock: {
    email: 'e2e-out-of-stock@example.com',
    password: 'password',
    firstName: 'Sam',
    lastName: 'Subscriber',
    usedBy: ['regression/outOfStock.spec.ts'],
  },
  reviews: {
    email: 'e2e-reviews@example.com',
    password: 'password',
    firstName: 'Rita',
    lastName: 'Reviewer',
    usedBy: ['regression/reviews.spec.ts'],
  },
  reviewsNonBuyer: {
    email: 'e2e-reviews-nonbuyer@example.com',
    password: 'password',
    firstName: 'Nina',
    lastName: 'Nonbuyer',
    usedBy: ['regression/reviews.spec.ts'],
  },
  checkout: {
    email: 'e2e-checkout@example.com',
    password: 'password',
    firstName: 'Chris',
    lastName: 'Checkout',
    usedBy: ['regression/checkoutEdgeCases.spec.ts'],
  },
  // Deactivated and restored, so it signs in through the form (no saved session).
  deactivate: {
    email: 'e2e-deactivate@example.com',
    password: 'password',
    firstName: 'Dana',
    lastName: 'Deactivate',
    usedBy: ['regression/deactivateUser.spec.ts'],
  },
  // Has a seeded Flannel Shirt order; writes a review that admin deletes.
  reviewModeration: {
    email: 'e2e-review-moderation@example.com',
    password: 'password',
    firstName: 'Mo',
    lastName: 'Moderated',
    usedBy: ['regression/reviewModeration.spec.ts'],
  },
  // Tries admin pages and another customer's order. Changes nothing.
  access: {
    email: 'e2e-access@example.com',
    password: 'password',
    firstName: 'Ace',
    lastName: 'Access',
    usedBy: ['regression/accessControl.spec.ts'],
  },
  // Accessibility scans of signed-in pages; adds one item to the cart for checkout.
  a11y: {
    email: 'e2e-a11y@example.com',
    password: 'password',
    firstName: 'Ally',
    lastName: 'Checker',
    usedBy: ['accessibility/pages.spec.ts'],
  },
} as const satisfies Record<string, SeededUser>

// Fake payment cards (app/models/payment/fake_gateway.rb). Any future expiry and
// any 3-digit code work.
export const TEST_CARDS = {
  success: '4242 4242 4242 4242',
  declined: '4000 0000 0000 0002',
} as const

// The purchase account's seeded billing address (db/seeds.rb). Tests must not change it.
export const PURCHASE_BILLING = {
  name: 'Pat Purchase',
  line1: '42 Oak Avenue',
  city: 'Springfield',
  state: 'IL',
  zip: '62702',
} as const

// Addresses for checkout tests.
export const TEST_ADDRESS = {
  line1: '1 Test Street',
  city: 'Springfield',
  state: 'IL',
  zip: '62701',
} as const

export const TEST_WORK_ADDRESS = {
  line1: '500 Office Park',
  city: 'Chicago',
  state: 'IL',
  zip: '60601',
} as const

// An expiry date two years from now, as MM/YY.
export function futureExpiry(): string {
  const year = (new Date().getFullYear() + 2) % 100
  return `12/${String(year).padStart(2, '0')}`
}

// Seeded reviews (db/seeds.rb): 8 on the T-Shirt (newest first), averaging 4.0.
export const SEEDED_REVIEWS = {
  tShirtCount: 8,
  tShirtAverage: '4.0',
} as const

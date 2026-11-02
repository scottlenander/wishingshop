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
    changes: false,
    usedBy: [],
  },
  BEANIE: {
    name: 'Beanie',
    sku: 'BEANIE',
    seededStock: 'in',
    // Stock updated by CSV import.
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
  CARDIGAN: { name: 'Cardigan', sku: 'CARDIGAN', seededStock: 'in', changes: false, usedBy: [] },
  CARGO_SHORTS: {
    name: 'Cargo Shorts',
    sku: 'CARGO-SHORTS',
    seededStock: 'out',
    changes: false,
    usedBy: [],
  },
  CHINOS: {
    name: 'Chinos',
    sku: 'CHINOS',
    seededStock: 'in',
    // Added to Bob's cart; the declined payment leaves stock unchanged.
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
    changes: false,
    usedBy: [],
  },
  GRAPHIC_TEE: {
    name: 'Graphic Tee',
    sku: 'GRAPHIC-TEE',
    seededStock: 'in',
    changes: false,
    usedBy: [],
  },
  HOODIE: {
    name: 'Hoodie',
    sku: 'HOODIE',
    seededStock: 'out',
    // Stock set to 0 then restocked; Alice subscribes.
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
    // Bob buys 1 per run while saving addresses at checkout.
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
    changes: false,
    usedBy: [],
  },
  RAIN_COAT: { name: 'Rain Coat', sku: 'RAIN-COAT', seededStock: 'in', changes: false, usedBy: [] },
  SCARF: {
    name: 'Scarf',
    sku: 'SCARF',
    seededStock: 'in',
    // Stock set to 10, then Alice checks out 3.
    changes: true,
    usedBy: ['regression/purchase.spec.ts'],
  },
  SWEATPANTS: {
    name: 'Sweatpants',
    sku: 'SWEATPANTS',
    seededStock: 'in',
    // Added to a visitor cart, which moves to Bob's cart on login. Not bought.
    changes: false,
    usedBy: ['regression/checkoutEdgeCases.spec.ts'],
  },
  T_SHIRT: {
    name: 'T-Shirt',
    sku: 'T-SHIRT',
    seededStock: 'in',
    // Read-only, so it can be shared.
    changes: false,
    usedBy: ['smoke/standardUserPath.spec.ts', 'smoke/adminUserPath.spec.ts'],
  },
  WOOL_SWEATER: {
    name: 'Wool Sweater',
    sku: 'WOOL-SWEATER',
    seededStock: 'in',
    changes: false,
    usedBy: [],
  },
} as const satisfies Record<string, SeededProduct>

// Seeded accounts (db/seeds.rb). All use the same password.
export const USERS = {
  admin: {
    email: 'admin@example.com',
    password: 'password',
    firstName: 'Admin',
    lastName: 'Manager',
  },
  alice: {
    email: 'alice@example.com',
    password: 'password',
    firstName: 'Alice',
    lastName: 'Cooper',
  },
  bob: { email: 'bob@example.com', password: 'password', firstName: 'Bob', lastName: 'Builder' },
} as const

// Fake payment cards (app/models/payment/fake_gateway.rb). Any future expiry and
// any 3-digit code work.
export const TEST_CARDS = {
  success: '4242 4242 4242 4242',
  declined: '4000 0000 0000 0002',
} as const

// Alice's seeded billing address (db/seeds.rb). Tests must not change it.
export const ALICE_BILLING = {
  name: 'Alice Cooper',
  line1: '18 Elm Street',
  city: 'Springfield',
  state: 'IL',
  zip: '62704',
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

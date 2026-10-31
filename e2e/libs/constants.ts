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
  T_SHIRT: {
    name: 'T-Shirt',
    sku: 'T-SHIRT',
    seededStock: 'in',
    // Read-only, so it can be shared.
    changes: false,
    usedBy: ['smoke/standardUserPath.spec.ts', 'smoke/adminUserPath.spec.ts'],
  },
  GRAPHIC_TEE: {
    name: 'Graphic Tee',
    sku: 'GRAPHIC-TEE',
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
  OXFORD_SHIRT: {
    name: 'Oxford Shirt',
    sku: 'OXFORD-SHIRT',
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
  DENIM_JACKET: {
    name: 'Denim Jacket',
    sku: 'DENIM-JACKET',
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
  WOOL_SWEATER: {
    name: 'Wool Sweater',
    sku: 'WOOL-SWEATER',
    seededStock: 'in',
    changes: false,
    usedBy: [],
  },
  RAIN_COAT: { name: 'Rain Coat', sku: 'RAIN-COAT', seededStock: 'in', changes: false, usedBy: [] },
  BOMBER_JACKET: {
    name: 'Bomber Jacket',
    sku: 'BOMBER-JACKET',
    seededStock: 'in',
    changes: false,
    usedBy: [],
  },
  CARDIGAN: { name: 'Cardigan', sku: 'CARDIGAN', seededStock: 'in', changes: false, usedBy: [] },
  PUFFER_VEST: {
    name: 'Puffer Vest',
    sku: 'PUFFER-VEST',
    seededStock: 'out',
    changes: false,
    usedBy: [],
  },
  CHINOS: { name: 'Chinos', sku: 'CHINOS', seededStock: 'in', changes: false, usedBy: [] },
  SWEATPANTS: {
    name: 'Sweatpants',
    sku: 'SWEATPANTS',
    seededStock: 'in',
    changes: false,
    usedBy: [],
  },
  LINEN_PANTS: {
    name: 'Linen Pants',
    sku: 'LINEN-PANTS',
    seededStock: 'in',
    changes: false,
    usedBy: [],
  },
  CARGO_SHORTS: {
    name: 'Cargo Shorts',
    sku: 'CARGO-SHORTS',
    seededStock: 'out',
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
  BASEBALL_CAP: {
    name: 'Baseball Cap',
    sku: 'BASEBALL-CAP',
    seededStock: 'in',
    changes: false,
    usedBy: [],
  },
  SCARF: {
    name: 'Scarf',
    sku: 'SCARF',
    seededStock: 'in',
    // Stock set to 10, then Alice buys 2.
    changes: true,
    usedBy: ['regression/purchase.spec.ts'],
  },
  LEATHER_BELT: {
    name: 'Leather Belt',
    sku: 'LEATHER-BELT',
    seededStock: 'in',
    changes: false,
    usedBy: [],
  },
} as const satisfies Record<string, SeededProduct>

// Seeded accounts (db/seeds.rb). All use the same password.
export const USERS = {
  admin: { email: 'admin@example.com', password: 'password' },
  alice: { email: 'alice@example.com', password: 'password' },
  bob: { email: 'bob@example.com', password: 'password' },
} as const

import path from 'node:path'

// Saved signed-in sessions, written by tests/auth.setup.ts before the other tests
// run. Tests start signed in with `test.use({ storageState: AUTH_FILES.admin })`,
// or `browser.newContext({ storageState: AUTH_FILES.admin })` for a second user.
// One file per account in USERS (libs/constants.ts) that a spec starts signed in as.
// Kept in playwright/.auth/, which is git-ignored.
const authFile = (name: string) => path.join(__dirname, `../playwright/.auth/${name}.json`)

export const AUTH_FILES = {
  admin: authFile('admin'),
  purchase: authFile('purchase'),
  outOfStock: authFile('out-of-stock'),
  reviews: authFile('reviews'),
  reviewsNonBuyer: authFile('reviews-nonbuyer'),
  checkout: authFile('checkout'),
} as const

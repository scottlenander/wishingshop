import path from 'node:path'

// Saved signed-in sessions, written by tests/auth.setup.ts before the other tests
// run. Tests start signed in with `test.use({ storageState: AUTH_FILES.admin })`,
// or `browser.newContext({ storageState: AUTH_FILES.admin })` for a second user.
// Kept in playwright/.auth/, which is git-ignored.
export const AUTH_FILES = {
  admin: path.join(__dirname, '../playwright/.auth/admin.json'),
  alice: path.join(__dirname, '../playwright/.auth/alice.json'),
  bob: path.join(__dirname, '../playwright/.auth/bob.json'),
} as const

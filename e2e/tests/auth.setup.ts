import fs from 'node:fs'
import { test as setup, expect, type Browser } from '@playwright/test'
import { LoginPage } from '../pageObjects/loginPage'
import { MainPage } from '../pageObjects/mainPage'
import { MySubscriptions } from '../pageObjects/mySubscriptions'
import { AUTH_FILES } from '../libs/auth'
import { USERS } from '../libs/constants'

// Signs in once per account and saves the session for the other tests, so a run
// only logs in a few times. bin/e2e-server raises the login rate limit (normally
// 10 per 3 minutes); restart a reused server after changing it.

const ACCOUNTS = [
  { role: 'admin', user: USERS.admin, file: AUTH_FILES.admin },
  { role: 'purchase', user: USERS.purchase, file: AUTH_FILES.purchase },
  { role: 'out-of-stock', user: USERS.outOfStock, file: AUTH_FILES.outOfStock },
  { role: 'reviews', user: USERS.reviews, file: AUTH_FILES.reviews },
  { role: 'reviews-nonbuyer', user: USERS.reviewsNonBuyer, file: AUTH_FILES.reviewsNonBuyer },
  { role: 'checkout', user: USERS.checkout, file: AUTH_FILES.checkout },
  { role: 'review-moderation', user: USERS.reviewModeration, file: AUTH_FILES.reviewModeration },
  { role: 'access', user: USERS.access, file: AUTH_FILES.access },
  { role: 'a11y', user: USERS.a11y, file: AUTH_FILES.a11y },
] as const

// A saved session is reused only if the server still knows it AND it belongs to
// the right account. After a reseed, session ids restart, so an old cookie could
// point at someone else's new session; My subscriptions shows whose it is.
async function savedSessionWorks(browser: Browser, file: string, email: string) {
  if (!fs.existsSync(file)) return false

  const context = await browser.newContext({ storageState: file })
  const page = await context.newPage()
  const mySubscriptions = new MySubscriptions(page)
  await mySubscriptions.goto()
  const works = await mySubscriptions.page.getByText(`We'll email ${email} when`).isVisible()
  await context.close()
  return works
}

for (const { role, user, file } of ACCOUNTS) {
  setup(`sign in as ${role}`, async ({ page, browser }) => {
    if (await savedSessionWorks(browser, file, user.email)) return

    const loginPage = new LoginPage(page)
    await loginPage.goto()
    await loginPage.emailInput.fill(user.email)
    await loginPage.passwordInput.fill(user.password)
    await loginPage.signInButton.click()
    await expect(new MainPage(page).logoutButton).toBeVisible()

    await page.context().storageState({ path: file })
  })
}

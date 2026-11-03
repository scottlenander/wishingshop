import { test, expect, type Browser, type Page } from '@playwright/test'
import { MainPage } from '../../pageObjects/mainPage'
import { LoginPage } from '../../pageObjects/loginPage'
import { LetterOpener } from '../../pageObjects/letterOpener'
import { PasswordReset } from '../../pageObjects/passwordReset'
import { AdminUsers } from '../../pageObjects/admin/users'
import { USERS } from '../../libs/constants'
import { AUTH_FILES } from '../../libs/auth'
import { TestData } from '../../libs/testData'

// Only these tests deactivate this account, and both change it, so they run in order.
const USER = USERS.deactivate
test.describe.configure({ mode: 'serial' })

const DEACTIVATED_ALERT =
  'This account is deactivated. Use “Forgot password?” to reset your password and reactivate it.'

// Signs in through the form in a fresh browser (the account has no saved session,
// since deactivating ends its sessions). Returns the page, still on the result.
async function logInAsUser(browser: Browser): Promise<Page> {
  // An empty storage state, so it never picks up the admin session from test.use.
  const context = await browser.newContext({ storageState: { cookies: [], origins: [] } })
  const page = await context.newPage()
  const loginPage = new LoginPage(page)
  await loginPage.goto()
  await loginPage.emailInput.fill(USER.email)
  await loginPage.passwordInput.fill(USER.password)
  await loginPage.signInButton.click()
  return page
}

test.describe('admin', () => {
  test.use({ storageState: AUTH_FILES.admin })

  test("deactivates a user, who can't log in until restored", async ({
    page,
    browser,
    request,
  }) => {
    const mainPage = new MainPage(page)
    const users = new AdminUsers(page)

    await test.step('Start with the user active', async () => {
      await new TestData(request).setUserActive(USER.email, true)
    })

    await test.step('Deactivate from the Users page', async () => {
      await mainPage.goto()
      await mainPage.usersLink.click()
      await expect(users.header).toBeVisible()
      await users.deactivate(USER.email)

      await expect(mainPage.notice).toHaveText(
        `${USER.email} deactivated. Their orders and reviews are kept.`,
      )
      await expect(users.activeRow(USER.email)).toHaveCount(0)
      await expect(users.deactivatedRow(USER.email)).toBeVisible()
    })

    await test.step("Their email can't be used for a new user", async () => {
      await users.newLink.click()
      await users.firstNameInput.fill('Copy')
      await users.lastNameInput.fill('Cat')
      await users.emailInput.fill(USER.email)
      await users.passwordInput.fill('secret123')
      await users.passwordConfirmationInput.fill('secret123')
      await users.saveButton.click()
      await expect(users.error).toHaveText(
        'Email address belongs to a deactivated user. Restore them from the Users page instead',
      )
    })

    await test.step('The user is told how to reactivate when logging in', async () => {
      const userPage = await logInAsUser(browser)
      await expect(new MainPage(userPage).alert).toHaveText(DEACTIVATED_ALERT)
      await expect(new MainPage(userPage).greeting).toBeHidden()
      await userPage.context().close()
    })

    await test.step('Restore, and they can log in again', async () => {
      await users.goto()
      await users.restoreButton(USER.email).click()
      await expect(mainPage.notice).toHaveText(`${USER.email} restored.`)
      await expect(users.activeRow(USER.email)).toBeVisible()

      const userPage = await logInAsUser(browser)
      await expect(new MainPage(userPage).greeting).toHaveText(`Hi, ${USER.firstName}!`)
      await userPage.context().close()
    })
  })
})

test('a deactivated user reactivates by resetting their password', async ({ page, request }) => {
  const mainPage = new MainPage(page)
  const loginPage = new LoginPage(page)
  const passwordReset = new PasswordReset(page)
  const letterOpener = new LetterOpener(page)
  let lettersBefore = 0

  await test.step('Start deactivated', async () => {
    // Deactivating through the Users page is tested above.
    await new TestData(request).setUserActive(USER.email, false)
    // Earlier runs leave emails to this address in the inbox, so look for one more.
    await letterOpener.goto()
    lettersBefore = await letterOpener.letter(USER.email).count()
  })

  await test.step('Logging in says to reset the password', async () => {
    await loginPage.goto()
    await loginPage.emailInput.fill(USER.email)
    await loginPage.passwordInput.fill(USER.password)
    await loginPage.signInButton.click()
    await expect(mainPage.alert).toHaveText(DEACTIVATED_ALERT)
  })

  await test.step('Ask for a reset email', async () => {
    await loginPage.forgotPasswordLink.click()
    await expect(passwordReset.requestHeader).toBeVisible()
    await passwordReset.emailInput.fill(USER.email)
    await passwordReset.sendButton.click()
    await expect(mainPage.notice).toContainText('Password reset instructions sent')
  })

  await test.step('The email says resetting reactivates the account', async () => {
    await letterOpener.goto()
    await letterOpener.waitForLetters(USER.email, lettersBefore + 1)
    await letterOpener.openLetter(USER.email)
    await expect(
      letterOpener.mailBody.getByText('Resetting your password will also reactivate your account.'),
    ).toBeVisible()
  })

  await test.step('Choose a new password from the link', async () => {
    const link = letterOpener.mailBody.getByRole('link', { name: 'this password reset page' })
    const href = await link.getAttribute('href')
    expect(href, 'the link points at this server').toMatch(/^http:\/\/localhost:\d+\/passwords\//)
    await page.goto(href ?? '')

    await expect(passwordReset.updateHeader).toBeVisible()
    // Same password as before, so the account's details stay fixed between runs.
    await passwordReset.passwordInput.fill(USER.password)
    await passwordReset.confirmationInput.fill(USER.password)
    await passwordReset.saveButton.click()
    await expect(mainPage.notice).toHaveText(
      'Password has been reset and your account is active again.',
    )
  })

  await test.step('They can log in again', async () => {
    await loginPage.emailInput.fill(USER.email)
    await loginPage.passwordInput.fill(USER.password)
    await loginPage.signInButton.click()
    await expect(mainPage.greeting).toHaveText(`Hi, ${USER.firstName}!`)
  })
})

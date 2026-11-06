import { test, expect, type Page } from '@playwright/test'
import { MainPage } from '../../pageObjects/mainPage'
import { LoginPage } from '../../pageObjects/loginPage'
import { SignUpPage } from '../../pageObjects/signUpPage'
import { AccountPage } from '../../pageObjects/accountPage'
import { ReactivationPage } from '../../pageObjects/reactivationPage'
import { MyAddresses } from '../../pageObjects/myAddresses'
import { AddressFields } from '../../pageObjects/checkout'
import { TEST_ADDRESS } from '../../libs/constants'

// A brand-new account every run (no seeded account), followed from sign-up to
// closing and coming back. Each step builds on the last, so they run in order.
test.describe.configure({ mode: 'serial' })

async function logIn(page: Page, email: string, password: string) {
  const loginPage = new LoginPage(page)
  await loginPage.goto()
  await loginPage.emailInput.fill(email)
  await loginPage.passwordInput.fill(password)
  await loginPage.signInButton.click()
}

test('a new customer signs up, manages their account, closes it and comes back', async ({
  page,
}) => {
  const mainPage = new MainPage(page)
  const signUp = new SignUpPage(page)
  const account = new AccountPage(page)
  const reactivation = new ReactivationPage(page)
  const myAddresses = new MyAddresses(page)

  const runId = Date.now()
  const firstEmail = `e2e-signup-${runId}@example.com`
  const changedEmail = `e2e-signup-${runId}-changed@example.com`
  const comebackEmail = `e2e-signup-${runId}-back@example.com`
  const firstPassword = 'first-pass-1'
  const newPassword = 'second-pass-2'

  await test.step('A visitor signs up and is logged straight in', async () => {
    await mainPage.goto()
    await mainPage.signUpLink.click()
    await expect(signUp.header).toBeVisible()
    await signUp.signUp({
      firstName: 'Sam',
      lastName: 'Signup',
      email: firstEmail,
      password: firstPassword,
    })

    await expect(mainPage.notice).toHaveText('Welcome to WishingShop, Sam!')
    await expect(mainPage.greeting).toHaveText('Hi, Sam!')
  })

  await test.step('The optional next step adds a billing address', async () => {
    await expect(
      page.getByRole('heading', { name: 'Add your billing address (optional)' }),
    ).toBeVisible()
    await expect(page.getByRole('link', { name: 'Skip for now' })).toBeVisible()

    await new AddressFields(page.locator('.form-card')).fill(TEST_ADDRESS)
    await page.getByRole('button', { name: 'Save address' }).click()
    await expect(myAddresses.billing).toContainText(TEST_ADDRESS.line1)
  })

  await test.step('My account shows their details; the name can be changed', async () => {
    await mainPage.greeting.click()
    await expect(account.header).toBeVisible()
    await expect(account.details).toContainText('Sam Signup')
    await expect(account.details).toContainText(firstEmail)

    await account.editDetailsLink.click()
    await expect(account.editDetailsHeader).toBeVisible()
    await account.firstNameInput.fill('Samantha')
    await account.saveDetailsButton.click()
    await expect(mainPage.notice).toHaveText('Your details are updated.')
    await expect(mainPage.greeting).toHaveText('Hi, Samantha!')
  })

  await test.step('Changing the email needs the current password', async () => {
    await account.editDetailsLink.click()
    await expect(account.editDetailsHeader).toBeVisible()
    await account.emailInput.fill(changedEmail)
    await account.currentPasswordInput.fill('not-my-password')
    await account.saveDetailsButton.click()
    await expect(account.error).toHaveText('Current password is incorrect')

    await account.currentPasswordInput.fill(firstPassword)
    await account.saveDetailsButton.click()
    await expect(mainPage.notice).toHaveText('Your details are updated.')
    await expect(account.details).toContainText(changedEmail)
  })

  await test.step('Change the password, then log in with it', async () => {
    await account.changePasswordLink.click()
    await expect(account.changePasswordHeader).toBeVisible()
    await account.currentPasswordInput.fill(firstPassword)
    await account.newPasswordInput.fill(newPassword)
    await account.confirmNewPasswordInput.fill(newPassword)
    await account.changePasswordButton.click()
    await expect(mainPage.notice).toHaveText('Password changed.')

    await mainPage.logoutButton.click()
    // Let the logout finish, or its response could clear the next login's cookie.
    await expect(mainPage.loginLink).toBeVisible()
    await logIn(page, changedEmail, newPassword)
    await expect(mainPage.greeting).toHaveText('Hi, Samantha!')
  })

  await test.step('Close the account', async () => {
    await account.goto()
    await account.close(newPassword)
    await expect(mainPage.notice).toHaveText(
      'Your account is closed. Log in again any time to reactivate it.',
    )
    await expect(mainPage.loginLink).toBeVisible()
  })

  await test.step('Logging in again offers to reactivate, here with a new email', async () => {
    await logIn(page, changedEmail, newPassword)
    await expect(reactivation.header).toBeVisible()
    await expect(reactivation.emailInput).toHaveValue(changedEmail)
    await expect(mainPage.greeting).toBeHidden()

    await reactivation.emailInput.fill(comebackEmail)
    await reactivation.reactivateButton.click()
    await expect(mainPage.notice).toHaveText(
      'Welcome back, Samantha! Your account is active again.',
    )
    await expect(mainPage.greeting).toHaveText('Hi, Samantha!')
  })

  await test.step('Everything is still there, under the new email', async () => {
    await mainPage.greeting.click()
    await expect(account.details).toContainText(comebackEmail)
    await account.addressesLink.click()
    await expect(myAddresses.billing).toContainText(TEST_ADDRESS.line1)
  })

  await test.step('The old email is free again, but a closed account keeps its email', async () => {
    await mainPage.logoutButton.click()
    // Let the logout finish, or its response could clear the next login's cookie.
    await expect(mainPage.loginLink).toBeVisible()

    // The account moved to a new email, so the old one can sign up afresh.
    await signUp.goto()
    await signUp.signUp({
      firstName: 'Second',
      lastName: 'Account',
      email: changedEmail,
      password: firstPassword,
    })
    await expect(mainPage.greeting).toHaveText('Hi, Second!')

    // Once that account is closed, its email points the person to logging in.
    await account.goto()
    await account.close(firstPassword)
    await expect(mainPage.loginLink).toBeVisible()
    await signUp.goto()
    await signUp.signUp({
      firstName: 'Third',
      lastName: 'Try',
      email: changedEmail,
      password: firstPassword,
    })
    await expect(signUp.error).toHaveText(
      'Email address belongs to a closed account. Log in with it to reactivate the account',
    )
  })
})

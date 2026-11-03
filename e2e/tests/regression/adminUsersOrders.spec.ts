import { test, expect } from '@playwright/test'
import { MainPage } from '../../pageObjects/mainPage'
import { AdminUsers } from '../../pageObjects/admin/users'
import { AdminOrders } from '../../pageObjects/admin/orders'
import { AUTH_FILES } from '../../libs/auth'

// Starts signed in (see tests/auth.setup.ts).
test.use({ storageState: AUTH_FILES.admin })

test('admin adds and edits a user', async ({ page }) => {
  const mainPage = new MainPage(page)
  const users = new AdminUsers(page)
  // New every run. Deactivated at the end, since users are never deleted.
  const email = `e2e-new-${Date.now()}@example.com`

  await test.step('Add a user', async () => {
    await mainPage.goto()
    await mainPage.usersLink.click()
    await users.newLink.click()
    await users.firstNameInput.fill('Newt')
    await users.lastNameInput.fill('Person')
    await users.emailInput.fill(email)
    await users.passwordInput.fill('secret123')
    await users.passwordConfirmationInput.fill('secret123')
    await users.saveButton.click()

    await expect(mainPage.notice).toHaveText('User created.')
    await expect(users.activeRow(email)).toContainText('Newt Person')
  })

  await test.step('Rename them, leaving the password as it is', async () => {
    await users.activeRow(email).getByRole('link', { name: 'Edit' }).click()
    await expect(users.emailInput).toHaveValue(email)
    await users.firstNameInput.fill('Newton')
    await users.saveButton.click()

    await expect(mainPage.notice).toHaveText('User updated.')
    await expect(users.activeRow(email)).toContainText('Newton Person')
  })

  await test.step('Clean up', async () => {
    await users.deactivate(email)
    await expect(users.deactivatedRow(email)).toBeVisible()
  })
})

test("admin sees every customer's orders", async ({ page }) => {
  const mainPage = new MainPage(page)
  const orders = new AdminOrders(page)

  await mainPage.goto()
  await mainPage.ordersLink.click()
  await expect(orders.header).toBeVisible()
  // Seeded: reviewer1 bought the T-Shirt and the Denim Jacket.
  await expect(orders.ordersFor('reviewer1@example.com')).toHaveCount(2)
  await expect(orders.ordersFor('reviewer1@example.com').first()).toContainText(/WS-/)
})

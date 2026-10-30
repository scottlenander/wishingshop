import { test, expect } from '@playwright/test'
import { MainPage } from '../../pageObjects/mainPage'
import { LoginPage } from '../../pageObjects/loginPage'

test('Admin User smoke test', async ({ page }) => {
  const mainPage = new MainPage(page)
  const loginPage = new LoginPage(page)
  const { products } = mainPage
  const { item } = products

  await test.step('Navigate to homepage', async () => {
    await mainPage.goto()
    await expect(products.header, {
      message: 'Products heading should be visible',
    }).toBeVisible()
  })

  await test.step('Log in as admin user', async () => {
    await mainPage.loginLink.click()
    await loginPage.emailInput.fill('admin@example.com')
    await loginPage.passwordInput.fill('password')
    await loginPage.signInButton.click()
    await expect(mainPage.loginLink, {
      message: 'Login link should not be present after login',
    }).not.toBeVisible()
    await expect(mainPage.usersLink, {
      message: 'Users link should be visible for admin users.',
    }).toBeVisible()
    await expect(mainPage.subscribersLink, {
      message: 'Subscribers link should be visible for admin users.',
    }).toBeVisible()
  })

  await test.step('Verify item page', async () => {
    await products.card('T-Shirt').link.click()
    await expect(item.image, {
      message: 'T-Shirt image should be present',
    }).toBeVisible()

    await expect(item.title).toHaveText('T-Shirt')
    await expect(item.description).toBeVisible()
    // In stock or out of stock, a status should always be shown.
    await expect(item.stockStatus).toBeVisible()

    await expect(item.editLink, {
      message: 'Edit link should be visible for admin users.',
    }).toBeVisible()
    await expect(item.deleteButton, {
      message: 'Delete stock button should be visible for admin users.',
    }).toBeVisible()
    await expect(item.backLink, {
      message: 'Back button should be present',
    }).toBeVisible()
  })

  await test.step('Return to Product page and log out', async () => {
    await item.backLink.click()
    await expect(products.header, {
      message: 'Products heading should be visible',
    }).toBeVisible()

    await mainPage.logoutButton.click()
    await expect(loginPage.emailInput).toBeVisible()
  })
})

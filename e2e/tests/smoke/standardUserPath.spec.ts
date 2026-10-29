import { test, expect } from '@playwright/test'

test('test', async ({ page }) => {
  await test.step('Navigate to homepage', async () => {
    await page.goto('http://localhost:3100/')
    await expect(page.getByRole('heading', { name: 'Products' }), {
      message: 'Products heading should be visible',
    }).toBeVisible()
  })

  await test.step('Log in as standard user', async () => {
    await page.getByRole('link', { name: 'Login' }).click()
    await page.getByRole('textbox', { name: 'Enter your email address' }).fill('alice@example.com')
    // await page.getByRole('textbox', { name: 'Enter your email address' }).press('Tab');
    await page.getByRole('textbox', { name: 'Enter your password' }).fill('password')
    await page.getByRole('textbox', { name: 'Enter your password' }).press('Enter') // form "Sign in" button or sessions-new__submit
    await expect(page.getByRole('link', { name: 'Login' }), {
      message: 'Login link should not be present after login',
    }).not.toBeVisible()
  })

  await test.step('Verify item page', async () => {
    await page.getByRole('link', { name: 'T-Shirt' }).click()
    // locator class="products-show__product"
    await expect(page.getByRole('img'), {
      message: 'T-Shirt image should be present',
    }).toBeVisible() // products-show__image

    // locator class="products-show__info"

    // assert item name in products-show__title
    await expect(page.getByRole('main')).toContainText(
      'Made from leather. Possimus vitae esse. Corrupti pariatur accusamus. Ullam illum ex.',
    ) // products-show__description
    // assert products-inventory__status is present
    // stock can be products-inventory__status--in-stock or products-inventory__status--out-of-stock
    await expect(page.getByRole('link', { name: 'Back' }), {
      message: 'Back button should be present',
    }).toBeVisible()
  })

  await test.step('Return to Product page and log out', async () => {
    await page.getByRole('link', { name: 'Back' }).click()
    await expect(page.getByRole('heading', { name: 'Products' }), {
      message: 'Products heading should be visible',
    }).toBeVisible()

    await page.getByRole('button', { name: 'Log out' }).click()
    await expect(page.getByRole('textbox', { name: 'Enter your email address' })).toBeVisible()
  })
})

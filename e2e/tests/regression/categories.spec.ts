import { test, expect } from '@playwright/test'
import { MainPage } from '../../pageObjects/mainPage'
import { PRODUCTS } from '../../libs/constants'

// Read-only: just looks at where seeded products are grouped.
const TOP = PRODUCTS.T_SHIRT.name
const ACCESSORY = PRODUCTS.SCARF.name

test('a visitor browses products grouped by category', async ({ page }) => {
  const mainPage = new MainPage(page)
  const { products } = mainPage
  const { item } = products

  await test.step('The products page has a section per category, in order', async () => {
    await mainPage.goto()
    // Other specs can add products (e.g. an import adds a jacket), so only the
    // order of the seeded categories is checked, not the number of cards.
    await expect(products.categoryTitles).toHaveText([
      'Tops',
      'Bottoms',
      'Accessories',
      'Jackets',
      'Hats',
    ])
    await expect(
      products.category('Tops').getByRole('link', { name: TOP, exact: true }),
    ).toBeVisible()
    await expect(
      products.category('Accessories').getByRole('link', { name: ACCESSORY, exact: true }),
    ).toBeVisible()
    await expect(
      products.category('Tops').getByRole('link', { name: ACCESSORY, exact: true }),
    ).toHaveCount(0)
  })

  await test.step('The product page shows its category, linking back to that section', async () => {
    await products.open(TOP)
    await expect(item.categoryLink).toHaveText('Tops')
    await item.categoryLink.click()

    await expect(page).toHaveURL(/\/products#category-tops$/)
    await expect(products.category('Tops')).toBeInViewport()
  })
})

import { test, expect } from '@playwright/test'
import { MainPage } from '../../pageObjects/mainPage'
import { LoginPage } from '../../pageObjects/loginPage'
import { Announcements } from '../../pageObjects/admin/announcements'
import { USERS } from '../../libs/constants'

// Every announcement this test creates starts with this, so leftovers are easy to clean up.
const TITLE_PREFIX = 'E2E announcement'

test('admin adds an announcement to the homepage carousel', async ({ page }) => {
  const mainPage = new MainPage(page)
  const loginPage = new LoginPage(page)
  const announcements = new Announcements(page)
  const { carousel } = mainPage
  const title = `${TITLE_PREFIX} ${Date.now()}`

  // Stops auto-advance, so slides only change when the test clicks.
  await page.emulateMedia({ reducedMotion: 'reduce' })

  await test.step('Log in as admin', async () => {
    await loginPage.goto()
    await loginPage.emailInput.fill(USERS.admin.email)
    await loginPage.passwordInput.fill(USERS.admin.password)
    await loginPage.signInButton.click()
    await expect(mainPage.logoutButton).toBeVisible()
  })

  await test.step('Remove announcements left by an earlier run', async () => {
    await mainPage.announcementsLink.click()
    await expect(announcements.header).toBeVisible()
    while ((await announcements.row(TITLE_PREFIX).count()) > 0) {
      await announcements.delete(TITLE_PREFIX)
      await expect(mainPage.notice).toHaveText('Announcement deleted.')
    }
  })

  await test.step('Create a sale announcement', async () => {
    await announcements.newLink.click()
    await announcements.kindSelect.selectOption({ label: 'Sale' })
    await announcements.titleInput.fill(title)
    await announcements.bodyInput.fill('Created by the Playwright test.')
    await announcements.positionInput.fill('99')
    await announcements.saveButton.click()

    await expect(mainPage.notice).toHaveText('Announcement created.')
    await expect(announcements.row(title)).toContainText('Live')
  })

  await test.step('It shows in the homepage carousel', async () => {
    await mainPage.goto()
    await expect(carousel.root).toBeVisible()
    await expect(carousel.slide(title)).toHaveCount(1)

    await carousel.showSlide(title)
    await expect(carousel.activeSlide).toContainText('Created by the Playwright test.')
    await expect(carousel.badge(carousel.activeSlide)).toHaveText('Sale')
  })

  await test.step('Previous, next and pause work', async () => {
    await carousel.dot(1).click()
    await expect(carousel.activeSlide).toHaveAttribute('aria-label', /^1 of \d+$/)
    await expect(carousel.dot(1)).toHaveAttribute('aria-current', 'true')

    await carousel.nextButton.click()
    await expect(carousel.activeSlide).toHaveAttribute('aria-label', /^2 of \d+$/)

    await carousel.previousButton.click()
    await carousel.previousButton.click()
    // Wraps around from the first slide to the last.
    const count = await carousel.slides.count()
    await expect(carousel.activeSlide).toHaveAttribute('aria-label', `${count} of ${count}`)

    // Reduced motion starts paused, so the button offers Play.
    await expect(carousel.pauseButton).toHaveAccessibleName('Play announcements')
    await carousel.pauseButton.click()
    await expect(carousel.pauseButton).toHaveAccessibleName('Pause announcements')
    await carousel.pauseButton.click()
    await expect(carousel.pauseButton).toHaveAccessibleName('Play announcements')
  })

  await test.step('Delete it; it leaves the carousel', async () => {
    await announcements.goto()
    await announcements.delete(title)
    await expect(mainPage.notice).toHaveText('Announcement deleted.')

    await mainPage.goto()
    await expect(carousel.slide(title)).toHaveCount(0)
  })
})

import { expect, type Locator, type Page } from '@playwright/test'

// Announcements carousel at the top of the products page.
// Only the active slide is visible; the others have the `hidden` attribute.
export class Carousel {
  readonly page: Page
  readonly root: Locator
  readonly slides: Locator
  readonly activeSlide: Locator
  readonly nextButton: Locator
  readonly previousButton: Locator
  readonly pauseButton: Locator
  readonly dots: Locator

  constructor(page: Page) {
    this.page = page
    this.root = page.getByRole('region', { name: 'Announcements' })
    this.slides = this.root.locator('[aria-roledescription="slide"]')
    this.activeSlide = this.root.locator('[aria-roledescription="slide"]:not([hidden])')
    this.nextButton = this.root.getByRole('button', { name: 'Next announcement' })
    this.previousButton = this.root.getByRole('button', { name: 'Previous announcement' })
    // Named "Pause announcements" while rotating, "Play announcements" when paused.
    this.pauseButton = this.root.getByRole('button', { name: /^(Pause|Play) announcements$/ })
    this.dots = this.root.getByRole('button', { name: /^Show slide \d+ of \d+$/ })
  }

  // Dot for slide n (1-based).
  dot(n: number): Locator {
    return this.root.getByRole('button', { name: new RegExp(`^Show slide ${n} of \\d+$`) })
  }

  // Slide containing the given title (may be hidden).
  slide(title: string): Locator {
    return this.slides.filter({ hasText: title })
  }

  badge(slide: Locator): Locator {
    return slide.locator('.carousel__badge')
  }

  // Clicks through the dots until the slide with this title is showing.
  async showSlide(title: string) {
    const count = await this.dots.count()
    for (let n = 1; n <= count; n++) {
      await this.dot(n).click()
      if (await this.activeSlide.filter({ hasText: title }).isVisible()) return
    }
    await expect(this.activeSlide, `No slide titled "${title}"`).toContainText(title)
  }
}

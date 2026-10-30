import type { FrameLocator, Locator, Page } from '@playwright/test'

// Development inbox from the letter_opener_web gem (/letter_opener).
// Sent emails are listed on the left. The selected one shows in an iframe (#mail)
// with its headers, and the HTML body sits in a second iframe nested inside it.
export class LetterOpener {
  readonly page: Page
  readonly letters: Locator
  readonly refreshButton: Locator
  readonly mail: FrameLocator
  readonly mailBody: FrameLocator

  constructor(page: Page) {
    this.page = page
    this.letters = page.locator('.letter-opener li')
    this.refreshButton = page.getByRole('link', { name: 'Refresh' })
    this.mail = page.frameLocator('#mail')
    this.mailBody = this.mail.frameLocator('iframe')
  }

  async goto() {
    await this.page.goto('/letter_opener')
  }

  // List entry whose headers (from, to, subject) contain the given text, e.g. a recipient.
  letter(text: string): Locator {
    return this.letters.filter({ hasText: text }).getByRole('link')
  }
}

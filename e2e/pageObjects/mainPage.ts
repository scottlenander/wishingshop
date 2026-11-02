import type { Locator, Page } from '@playwright/test'
import { Carousel } from './components/carousel'
import { Featured } from './components/featured'
import { Products } from './components/products'

// Main product page: site header, flash messages and the products section.
export class MainPage {
  readonly page: Page
  readonly homeLink: Locator
  readonly loginLink: Locator
  readonly logoutButton: Locator
  readonly myOrdersLink: Locator
  readonly mySubscriptionsLink: Locator
  readonly ordersLink: Locator
  readonly importLink: Locator
  readonly announcementsLink: Locator
  readonly featuredLink: Locator
  readonly usersLink: Locator
  readonly subscribersLink: Locator
  readonly notice: Locator
  readonly alert: Locator
  readonly carousel: Carousel
  readonly featured: Featured
  readonly products: Products

  constructor(page: Page) {
    this.page = page

    // Header nav
    this.homeLink = page.getByRole('link', { name: 'Home' })
    this.logoutButton = page.getByRole('button', { name: 'Log out' })
    this.myOrdersLink = page.getByRole('link', { name: 'My orders' }) // signed in
    this.mySubscriptionsLink = page.getByRole('link', { name: 'My subscriptions' }) // signed in
    // exact: otherwise "My orders" also matches.
    this.ordersLink = page.getByRole('link', { name: 'Orders', exact: true }) // admins only
    this.importLink = page.getByRole('link', { name: 'Import' }) // admins only
    this.announcementsLink = page.getByRole('link', { name: 'Announcements' }) // admins only
    this.featuredLink = page.getByRole('link', { name: 'Featured', exact: true }) // admins only
    this.usersLink = page.getByRole('link', { name: 'Users' }) // admins only
    this.subscribersLink = page.getByRole('link', { name: 'Subscribers' }) // admins only

    // Shown on the product list when signed out
    this.loginLink = page.getByRole('link', { name: 'Login' })

    // Flash messages
    this.notice = page.locator('.notice')
    this.alert = page.locator('.alert')

    // Top of the products page
    this.carousel = new Carousel(page)
    this.featured = new Featured(page)

    this.products = new Products(page)
  }

  async goto() {
    await this.page.goto('/')
  }
}

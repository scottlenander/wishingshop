import type { Locator, Page } from '@playwright/test'
import { Carousel } from './components/carousel'
import { Featured } from './components/featured'
import { Products } from './components/products'

// Main product page: site header, flash messages and the products section.
export class MainPage {
  readonly page: Page
  readonly homeLink: Locator
  readonly loginLink: Locator
  readonly signUpLink: Locator
  readonly logoutButton: Locator
  readonly greeting: Locator
  readonly cartLink: Locator
  readonly cartCount: Locator
  readonly myOrdersLink: Locator
  readonly mySubscriptionsLink: Locator
  readonly myAddressesLink: Locator
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

    // Header nav. Scoped to the nav with exact names, so product cards on the
    // page (e.g. "Import Jacket") never match.
    const nav = page.getByRole('navigation')
    const navLink = (name: string) => nav.getByRole('link', { name, exact: true })
    this.homeLink = nav.getByRole('link', { name: 'WishingShop' })
    this.logoutButton = nav.getByRole('button', { name: 'Log out' })
    this.myOrdersLink = navLink('My orders') // signed in
    this.mySubscriptionsLink = navLink('My subscriptions') // signed in
    this.myAddressesLink = navLink('My addresses') // signed in
    this.ordersLink = navLink('Orders') // admins only
    this.importLink = navLink('Import') // admins only
    this.announcementsLink = navLink('Announcements') // admins only
    this.featuredLink = navLink('Featured') // admins only
    this.usersLink = navLink('Users') // admins only
    this.subscribersLink = navLink('Subscribers') // admins only

    // Right end of the nav: Sign up and Login when signed out; "Hi, Alice!" (a link
    // to My account) and Log out when signed in.
    this.loginLink = navLink('Login')
    this.signUpLink = navLink('Sign up')
    this.greeting = page.getByTestId('nav-greeting')
    // Named "Cart, 2 items"; the badge shows the count when there are items.
    this.cartLink = nav.getByRole('link', { name: /^Cart, / })
    this.cartCount = page.getByTestId('cart-count')

    // Flash messages
    this.notice = page.getByTestId('flash-notice')
    this.alert = page.getByTestId('flash-alert')

    // Top of the products page
    this.carousel = new Carousel(page)
    this.featured = new Featured(page)

    this.products = new Products(page)
  }

  async goto() {
    await this.page.goto('/')
  }
}

import { expect, type APIRequestContext } from '@playwright/test'

// Quick set-up and clean-up through the e2e-only routes
// (app/controllers/e2e/data_controller.rb, on only when bin/e2e-server runs).
// Use these to get to a known starting point; anything a spec is testing must
// still go through the UI, and every change made here is also tested in the UI
// somewhere (see the README's Testing section).
//
//   test('...', async ({ page, request }) => {
//     const testData = new TestData(request)
//     await testData.resetUser(USERS.purchase.email, ['cart'])

export type ResetPart = 'cart' | 'addresses' | 'subscriptions' | 'reviews'

export class TestData {
  readonly request: APIRequestContext

  constructor(request: APIRequestContext) {
    this.request = request
  }

  // Clears a test account's cart, addresses, subscriptions and/or reviews (all if `only` is left out).
  async resetUser(email: string, only?: ResetPart[]) {
    await this.post('users/reset', { email, only })
  }

  // Sets a product's stock. Going from 0 to more emails its subscribers.
  async setStock(sku: string, inventoryCount: number) {
    await this.post('products/stock', { sku, inventory_count: inventoryCount })
  }

  async deleteAnnouncements(titlePrefix: string) {
    await this.post('announcements/delete', { title_prefix: titlePrefix })
  }

  async deleteFeaturedPicks(sku: string) {
    await this.post('featured_products/delete', { sku })
  }

  private async post(path: string, data: object) {
    const response = await this.request.post(`/e2e/${path}`, { data })
    expect(
      response.ok(),
      `POST /e2e/${path} returned ${response.status()}. Is the server running with E2E=1 (bin/e2e-server)?`,
    ).toBe(true)
  }
}

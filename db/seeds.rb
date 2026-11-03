# Development/test seed data. Safe to run more than once: bin/rails db:seed
#
# Test accounts (password for all: "password")
#   admin@example.com  - admin
#   alice@example.com  - regular user
#   bob@example.com    - regular user
#
# Subscribers (one per out-of-stock product; restock a product to send them an
# email, then view it at http://localhost:3000/letter_opener)
#   subscriber1@example.com, subscriber2@example.com, subscriber3@example.com
#
# Product images live in db/seeds/images and are made by script/generate_seed_images.rb.

if Rails.env.production?
  puts "Skipping seeds in production."
  return
end

PASSWORD = "password"

USERS = [
  { email_address: "admin@example.com", first_name: "Admin", last_name: "Manager", admin: true },
  { email_address: "alice@example.com", first_name: "Alice", last_name: "Cooper",  admin: false },
  { email_address: "bob@example.com",   first_name: "Bob",   last_name: "Builder", admin: false }
]

PRODUCT_NAMES = [
  "T-Shirt", "Graphic Tee", "Polo Shirt", "Oxford Shirt", "Flannel Shirt",
  "Denim Jacket", "Hoodie", "Wool Sweater", "Rain Coat", "Bomber Jacket",
  "Cardigan", "Puffer Vest", "Chinos", "Sweatpants", "Linen Pants",
  "Cargo Shorts", "Beanie", "Baseball Cap", "Scarf", "Leather Belt"
]

# Fixed prices (in cents), so re-seeding gives the same values.
PRICES = {
  "T-Shirt" => 19_99, "Graphic Tee" => 24_99, "Polo Shirt" => 34_99, "Oxford Shirt" => 49_99,
  "Flannel Shirt" => 44_99, "Denim Jacket" => 89_99, "Hoodie" => 54_99, "Wool Sweater" => 74_99,
  "Rain Coat" => 99_99, "Bomber Jacket" => 119_99, "Cardigan" => 59_99, "Puffer Vest" => 79_99,
  "Chinos" => 49_99, "Sweatpants" => 39_99, "Linen Pants" => 54_99, "Cargo Shorts" => 34_99,
  "Beanie" => 14_99, "Baseball Cap" => 19_99, "Scarf" => 14_99, "Leather Belt" => 29_99
}.freeze

SUBSCRIBER_EMAILS = %w[ subscriber1@example.com subscriber2@example.com subscriber3@example.com ]
IMAGE_DIR = Rails.root.join("db/seeds/images")

# A fixed seed gives the same descriptions, stock levels and out-of-stock items
# on every run, so re-seeding never flips a product back into stock (which
# would email its subscribers).
rng = Random.new(42)
Faker::Config.random = rng

# Users
USERS.each do |attrs|
  User.find_or_initialize_by(email_address: attrs[:email_address])
      .update!(first_name: attrs[:first_name], last_name: attrs[:last_name], admin: attrs[:admin],
               password: PASSWORD, password_confirmation: PASSWORD)
end

# Alice has a saved billing address (checkout fills it in); Bob has none.
alice = User.find_by!(email_address: "alice@example.com")
(alice.billing_address || alice.addresses.build(kind: :billing))
  .update!(name: "Alice Cooper", line1: "18 Elm Street", city: "Springfield", state: "IL", postal_code: "62704")

# Products: exactly 3 out of stock, the rest between 1 and 50.
out_of_stock = PRODUCT_NAMES.sample(3, random: rng)

products = PRODUCT_NAMES.map do |name|
  product = Product.find_or_initialize_by(name: name)
  product.sku = name.parameterize.upcase
  product.description = "Made from #{Faker::Commerce.material.downcase}. #{Faker::Lorem.paragraph(sentence_count: 3)}"
  product.inventory_count = out_of_stock.include?(name) ? 0 : rng.rand(1..50)
  product.price_cents = PRICES.fetch(name)

  image = IMAGE_DIR.join("#{name.parameterize}.png")
  if !product.featured_image.attached? && image.exist?
    product.featured_image.attach(io: File.open(image), filename: image.basename.to_s, content_type: "image/png")
  end

  product.save!
  product
end

# Subscribers: one per out-of-stock product.
oos_products = products.select { |p| p.inventory_count.zero? }
SUBSCRIBER_EMAILS.zip(oos_products).each do |email, product|
  product.subscribers.find_or_create_by!(email: email)
end

# Homepage carousel announcements. No admin featured pick, so the homepage
# shows the daily random featured product.
ANNOUNCEMENTS = [
  { title: "New: Rain Coat", kind: "new_product", position: 0,
    body: "Stay dry in style with our new lightweight rain coat.", products: [ "Rain Coat" ] },
  { title: "20% off scarves this week", kind: "sale", position: 1,
    body: "Wrap up for winter. Sale ends Sunday.", products: [ "Scarf" ] },
  { title: "Free shipping over $50", kind: "general", position: 2,
    body: "On every order, every day.", products: [] }
]
ANNOUNCEMENTS.each do |attrs|
  announcement = Announcement.find_or_initialize_by(title: attrs[:title])
  announcement.update!(kind: attrs[:kind], body: attrs[:body], position: attrs[:position],
                       starts_at: announcement.persisted? ? announcement.starts_at : 1.day.ago, ends_at: nil,
                       products: Product.where(name: attrs[:products]))
end

# Reviews. Only buyers can review, so each reviewer gets a past order first.
# 8 reviewer accounts review the T-Shirt (enough to show "Show more"), the
# first 3 also review the Denim Jacket. Alice has bought the Graphic Tee but
# hasn't reviewed it (the Playwright review test writes one).
def seed_past_order(user, product, placed_at)
  return if user.purchased?(product)

  user.orders.create!(
    placed_at: placed_at, shipping_method: "standard", subtotal_cents: product.price_cents,
    shipping_cents: 499, total_cents: product.price_cents + 499, card_brand: "Visa", card_last4: "4242",
    ship_name: user.full_name, ship_line1: "1 Seed Street", ship_city: "Springfield", ship_state: "IL", ship_postal_code: "62701",
    order_items: [ OrderItem.new(product: product, product_name: product.name, sku: product.sku,
                                 unit_price_cents: product.price_cents, quantity: 1) ]
  )
end

REVIEW_RATINGS = {
  "T-Shirt" => [ 5, 4, 5, 3, 4, 5, 2, 4 ],
  "Denim Jacket" => [ 4, 5, 3 ]
}.freeze

reviewers = (1..8).map do |n|
  User.find_or_initialize_by(email_address: "reviewer#{n}@example.com").tap do |user|
    user.update!(first_name: Faker::Name.first_name, last_name: Faker::Name.last_name,
                 password: PASSWORD, password_confirmation: PASSWORD) if user.new_record?
  end
end

REVIEW_RATINGS.each do |product_name, ratings|
  product = Product.find_by!(name: product_name)
  ratings.each_with_index do |rating, index|
    user = reviewers[index]
    reviewed_at = (index * 4 + 2).days.ago
    seed_past_order(user, product, reviewed_at - 5.days)
    next if product.reviews.exists?(user: user)

    product.reviews.create!(user: user, rating: rating, body: Faker::Lorem.paragraph(sentence_count: 3),
                            created_at: reviewed_at, updated_at: reviewed_at)
  end
end

seed_past_order(alice, Product.find_by!(name: "Graphic Tee"), 10.days.ago)

# Playwright accounts, one per spec, so specs never share a cart, addresses,
# subscriptions or reviews. Only seeded on the e2e server (bin/e2e-server sets
# E2E=1). Keep in step with USERS in e2e/libs/constants.ts.
E2E_USERS = [
  { email_address: "e2e-purchase@example.com",         first_name: "Pat",   last_name: "Purchase" },
  { email_address: "e2e-out-of-stock@example.com",     first_name: "Sam",   last_name: "Subscriber" },
  { email_address: "e2e-reviews@example.com",          first_name: "Rita",  last_name: "Reviewer" },
  { email_address: "e2e-reviews-nonbuyer@example.com", first_name: "Nina",  last_name: "Nonbuyer" },
  { email_address: "e2e-checkout@example.com",         first_name: "Chris", last_name: "Checkout" }
]

if ENV["E2E"] == "1"
  E2E_USERS.each do |attrs|
    User.find_or_initialize_by(email_address: attrs[:email_address])
        .update!(first_name: attrs[:first_name], last_name: attrs[:last_name], admin: false,
                 password: PASSWORD, password_confirmation: PASSWORD)
  end

  # purchase.spec: checkout fills in a saved billing address.
  purchaser = User.find_by!(email_address: "e2e-purchase@example.com")
  (purchaser.billing_address || purchaser.addresses.build(kind: :billing))
    .update!(name: "Pat Purchase", line1: "42 Oak Avenue", city: "Springfield", state: "IL", postal_code: "62702")

  # reviews.spec: has bought the Graphic Tee, so can review it.
  seed_past_order(User.find_by!(email_address: "e2e-reviews@example.com"), Product.find_by!(name: "Graphic Tee"), 10.days.ago)
end

puts <<~SUMMARY

  Seeded #{User.count} users, #{Product.count} products, #{Subscriber.count} subscribers, #{Announcement.count} announcements, #{Review.count} reviews.
  Reviewers: reviewer1@example.com ... reviewer8@example.com (password: "#{PASSWORD}"). The T-Shirt has 8 reviews.

  Logins (password: "#{PASSWORD}")
  #{USERS.map { |u| "  #{u[:email_address].ljust(20)} #{"#{u[:first_name]} #{u[:last_name]}".ljust(16)} #{u[:admin] ? "admin" : "user"}" }.join("\n")}

  Out of stock, with subscribers
  #{oos_products.map { |p| "  #{p.name.ljust(16)} #{p.subscribers.pluck(:email).join(", ")}" }.join("\n")}

  Restock one of these, then check http://localhost:3000/letter_opener
SUMMARY

puts "Playwright accounts: #{E2E_USERS.map { |u| u[:email_address] }.join(", ")}" if ENV["E2E"] == "1"

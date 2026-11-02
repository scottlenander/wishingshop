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

# Products: exactly 3 out of stock, the rest between 1 and 50.
out_of_stock = PRODUCT_NAMES.sample(3, random: rng)

products = PRODUCT_NAMES.map do |name|
  product = Product.find_or_initialize_by(name: name)
  product.sku = name.parameterize.upcase
  product.description = "Made from #{Faker::Commerce.material.downcase}. #{Faker::Lorem.paragraph(sentence_count: 3)}"
  product.inventory_count = out_of_stock.include?(name) ? 0 : rng.rand(1..50)

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

puts <<~SUMMARY

  Seeded #{User.count} users, #{Product.count} products, #{Subscriber.count} subscribers, #{Announcement.count} announcements.

  Logins (password: "#{PASSWORD}")
  #{USERS.map { |u| "  #{u[:email_address].ljust(20)} #{"#{u[:first_name]} #{u[:last_name]}".ljust(16)} #{u[:admin] ? "admin" : "user"}" }.join("\n")}

  Out of stock, with subscribers
  #{oos_products.map { |p| "  #{p.name.ljust(16)} #{p.subscribers.pluck(:email).join(", ")}" }.join("\n")}

  Restock one of these, then check http://localhost:3000/letter_opener
SUMMARY

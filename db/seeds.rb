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
  { email_address: "admin@example.com", admin: true },
  { email_address: "alice@example.com", admin: false },
  { email_address: "bob@example.com",   admin: false }
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
      .update!(admin: attrs[:admin], password: PASSWORD, password_confirmation: PASSWORD)
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

puts <<~SUMMARY

  Seeded #{User.count} users, #{Product.count} products, #{Subscriber.count} subscribers.

  Logins (password: "#{PASSWORD}")
  #{USERS.map { |u| "  #{u[:email_address].ljust(20)} #{u[:admin] ? "admin" : "user"}" }.join("\n")}

  Out of stock, with subscribers
  #{oos_products.map { |p| "  #{p.name.ljust(16)} #{p.subscribers.pluck(:email).join(", ")}" }.join("\n")}

  Restock one of these, then check http://localhost:3000/letter_opener
SUMMARY

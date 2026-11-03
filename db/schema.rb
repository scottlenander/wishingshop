# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_03_160226) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "addresses", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "kind", null: false
    t.string "nickname"
    t.string "name", null: false
    t.string "line1", null: false
    t.string "line2"
    t.string "city", null: false
    t.string "state", null: false
    t.string "postal_code", null: false
    t.string "country", default: "US", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "nickname"], name: "index_addresses_unique_shipping_nickname", unique: true, where: "kind = 'shipping'"
    t.index ["user_id"], name: "index_addresses_on_user_id"
    t.index ["user_id"], name: "index_addresses_one_billing_per_user", unique: true, where: "kind = 'billing'"
  end

  create_table "announcement_products", force: :cascade do |t|
    t.integer "announcement_id", null: false
    t.integer "product_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["announcement_id", "product_id"], name: "index_announcement_products_on_announcement_id_and_product_id", unique: true
    t.index ["announcement_id"], name: "index_announcement_products_on_announcement_id"
    t.index ["product_id"], name: "index_announcement_products_on_product_id"
  end

  create_table "announcements", force: :cascade do |t|
    t.string "kind", default: "general", null: false
    t.string "title", null: false
    t.text "body"
    t.datetime "starts_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "ends_at"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["starts_at", "ends_at"], name: "index_announcements_on_starts_at_and_ends_at"
  end

  create_table "cart_items", force: :cascade do |t|
    t.integer "cart_id", null: false
    t.integer "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cart_id", "product_id"], name: "index_cart_items_on_cart_id_and_product_id", unique: true
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["product_id"], name: "index_cart_items_on_product_id"
  end

  create_table "carts", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_carts_on_user_id", unique: true
  end

  create_table "featured_products", force: :cascade do |t|
    t.integer "product_id", null: false
    t.integer "user_id"
    t.datetime "starts_at", null: false
    t.datetime "ends_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_featured_products_on_product_id"
    t.index ["starts_at", "ends_at"], name: "index_featured_products_on_starts_at_and_ends_at"
    t.index ["user_id"], name: "index_featured_products_on_user_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.integer "order_id", null: false
    t.integer "product_id"
    t.string "product_name", null: false
    t.string "sku"
    t.integer "unit_price_cents", default: 0, null: false
    t.integer "quantity", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "orders", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "number", null: false
    t.string "status", default: "paid", null: false
    t.datetime "placed_at", null: false
    t.integer "subtotal_cents", default: 0, null: false
    t.integer "shipping_cents", default: 0, null: false
    t.integer "total_cents", default: 0, null: false
    t.string "shipping_method"
    t.string "ship_name"
    t.string "ship_line1"
    t.string "ship_line2"
    t.string "ship_city"
    t.string "ship_state"
    t.string "ship_postal_code"
    t.string "ship_country", default: "US", null: false
    t.string "card_brand"
    t.string "card_last4"
    t.string "bill_name"
    t.string "bill_line1"
    t.string "bill_line2"
    t.string "bill_city"
    t.string "bill_state"
    t.string "bill_postal_code"
    t.index ["number"], name: "index_orders_on_number", unique: true
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "inventory_count", default: 0
    t.string "sku", null: false
    t.integer "price_cents", default: 0, null: false
    t.index ["sku"], name: "index_products_on_sku", unique: true
  end

  create_table "reviews", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "product_id", null: false
    t.integer "rating", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id", "created_at"], name: "index_reviews_on_product_id_and_created_at"
    t.index ["product_id", "user_id"], name: "index_reviews_on_product_id_and_user_id", unique: true
    t.index ["user_id"], name: "index_reviews_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "subscribers", force: :cascade do |t|
    t.integer "product_id", null: false
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["product_id"], name: "index_subscribers_on_product_id"
    t.index ["user_id"], name: "index_subscribers_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin", default: false, null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "addresses", "users"
  add_foreign_key "announcement_products", "announcements"
  add_foreign_key "announcement_products", "products"
  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "products"
  add_foreign_key "carts", "users"
  add_foreign_key "featured_products", "products"
  add_foreign_key "featured_products", "users"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "users"
  add_foreign_key "reviews", "products"
  add_foreign_key "reviews", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "subscribers", "products"
  add_foreign_key "subscribers", "users"
end

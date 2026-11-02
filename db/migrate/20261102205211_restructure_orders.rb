# Turns an order from "one product" into a header with line items, shipping and
# payment details. Existing orders become an order with one item; their price
# wasn't recorded, so it's 0, and they have no address or payment.
class RestructureOrders < ActiveRecord::Migration[8.1]
  class MigrationOrder < ActiveRecord::Base
    self.table_name = "orders"
  end

  class MigrationOrderItem < ActiveRecord::Base
    self.table_name = "order_items"
  end

  def up
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      # Optional so history survives if an admin deletes the product.
      t.references :product, null: true, foreign_key: true
      t.string :product_name, null: false
      t.string :sku
      t.integer :unit_price_cents, null: false, default: 0
      t.integer :quantity, null: false

      t.timestamps
    end

    change_table :orders, bulk: true do |t|
      t.string :number
      t.string :status, null: false, default: "paid"
      t.datetime :placed_at
      t.integer :subtotal_cents, null: false, default: 0
      t.integer :shipping_cents, null: false, default: 0
      t.integer :total_cents, null: false, default: 0
      t.string :shipping_method
      t.string :ship_name
      t.string :ship_line1
      t.string :ship_line2
      t.string :ship_city
      t.string :ship_state
      t.string :ship_postal_code
      t.string :ship_country, null: false, default: "US"
      t.string :card_brand
      t.string :card_last4
    end

    MigrationOrder.reset_column_information
    MigrationOrder.find_each do |order|
      MigrationOrderItem.create!(order_id: order.id, product_id: order.product_id, product_name: order.product_name,
                                 quantity: order.quantity, unit_price_cents: 0,
                                 created_at: order.created_at, updated_at: order.updated_at)
      order.update_columns(number: "WS-L#{order.id.to_s.rjust(5, "0")}", placed_at: order.created_at)
    end

    change_column_null :orders, :number, false
    change_column_null :orders, :placed_at, false
    add_index :orders, :number, unique: true

    remove_reference :orders, :product, foreign_key: true, index: true
    remove_column :orders, :product_name
    remove_column :orders, :quantity
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Orders with several items can't be split back into one-product orders"
  end
end

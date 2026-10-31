class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      # Optional so order history survives if an admin deletes the product.
      t.references :product, null: true, foreign_key: true
      t.string :product_name, null: false
      t.integer :quantity, null: false

      t.timestamps
    end
  end
end

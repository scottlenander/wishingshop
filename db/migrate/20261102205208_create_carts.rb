class CreateCarts < ActiveRecord::Migration[8.1]
  def change
    create_table :carts do |t|
      # Empty for a visitor's cart (kept in their session).
      t.references :user, null: true, foreign_key: true, index: { unique: true }

      t.timestamps
    end
  end
end

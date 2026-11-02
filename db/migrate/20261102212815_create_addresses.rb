# Saved addresses: at most one billing address per user, plus any number of
# shipping addresses, each with a nickname ("Home", "Work").
class CreateAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :addresses do |t|
      t.references :user, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :nickname
      t.string :name, null: false
      t.string :line1, null: false
      t.string :line2
      t.string :city, null: false
      t.string :state, null: false
      t.string :postal_code, null: false
      t.string :country, null: false, default: "US"

      t.timestamps
    end
    add_index :addresses, :user_id, unique: true, where: "kind = 'billing'", name: "index_addresses_one_billing_per_user"
    add_index :addresses, %i[ user_id nickname ], unique: true, where: "kind = 'shipping'", name: "index_addresses_unique_shipping_nickname"
  end
end

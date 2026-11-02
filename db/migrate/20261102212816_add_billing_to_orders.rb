class AddBillingToOrders < ActiveRecord::Migration[8.1]
  def change
    # Copied in at checkout, like the shipping address.
    change_table :orders, bulk: true do |t|
      t.string :bill_name
      t.string :bill_line1
      t.string :bill_line2
      t.string :bill_city
      t.string :bill_state
      t.string :bill_postal_code
    end
  end
end

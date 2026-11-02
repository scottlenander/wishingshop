class AddPriceToProducts < ActiveRecord::Migration[8.1]
  def change
    # Whole cents, so money never has rounding errors. 0 means "not for sale yet".
    add_column :products, :price_cents, :integer, null: false, default: 0
  end
end

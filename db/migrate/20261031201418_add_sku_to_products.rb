class AddSkuToProducts < ActiveRecord::Migration[8.1]
  # Minimal model so the migration doesn't depend on app code that may change.
  class MigrationProduct < ActiveRecord::Base
    self.table_name = "products"
  end

  def up
    add_column :products, :sku, :string

    # Backfill from the name ("T-Shirt" -> "T-SHIRT"). Adds the id if two names
    # turn into the same SKU, so the unique index below can't fail.
    taken = Set.new
    MigrationProduct.find_each do |product|
      sku = product.name.to_s.parameterize.upcase.presence || "PRODUCT"
      sku = "#{sku}-#{product.id}" if taken.include?(sku)
      taken << sku
      product.update_columns(sku: sku)
    end

    change_column_null :products, :sku, false
    add_index :products, :sku, unique: true
  end

  def down
    remove_index :products, :sku
    remove_column :products, :sku
  end
end

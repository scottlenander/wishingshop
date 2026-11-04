class AddCategoryToProducts < ActiveRecord::Migration[8.1]
  # The seeded products, so existing databases get categories too. Written out
  # here rather than taken from the model, so this migration never changes.
  SEEDED = {
    "tops" => [ "T-Shirt", "Graphic Tee", "Polo Shirt", "Oxford Shirt", "Flannel Shirt", "Hoodie", "Wool Sweater", "Cardigan" ],
    "bottoms" => [ "Chinos", "Sweatpants", "Linen Pants", "Cargo Shorts" ],
    "accessories" => [ "Scarf", "Leather Belt" ],
    "jackets" => [ "Denim Jacket", "Bomber Jacket", "Rain Coat", "Puffer Vest" ],
    "hats" => [ "Beanie", "Baseball Cap" ]
  }.freeze

  def up
    # Nullable, so other existing products don't break the migration; the
    # model requires a category whenever a product is saved.
    add_column :products, :category, :string
    add_index :products, :category

    SEEDED.each do |category, names|
      execute(sanitize([ "UPDATE products SET category = ? WHERE name IN (?)", category, names ]))
    end
  end

  def down
    remove_index :products, :category
    remove_column :products, :category
  end

  private
    def sanitize(sql) = ActiveRecord::Base.sanitize_sql_array(sql)
end

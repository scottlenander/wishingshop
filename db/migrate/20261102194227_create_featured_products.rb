class CreateFeaturedProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :featured_products do |t|
      t.references :product, null: false, foreign_key: true
      # The admin who picked it.
      t.references :user, null: true, foreign_key: true
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false

      t.timestamps
    end
    add_index :featured_products, %i[ starts_at ends_at ]
  end
end

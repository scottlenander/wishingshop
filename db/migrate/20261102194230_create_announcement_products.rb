class CreateAnnouncementProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :announcement_products do |t|
      t.references :announcement, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true

      t.timestamps
    end
    add_index :announcement_products, %i[ announcement_id product_id ], unique: true
  end
end

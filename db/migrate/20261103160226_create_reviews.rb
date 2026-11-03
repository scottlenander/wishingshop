class CreateReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :reviews do |t|
      t.references :user, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true, index: false
      t.integer :rating, null: false
      t.text :body, null: false

      t.timestamps
    end
    # One review per user per product; newest-first listing per product.
    add_index :reviews, %i[ product_id user_id ], unique: true
    add_index :reviews, %i[ product_id created_at ]
  end
end

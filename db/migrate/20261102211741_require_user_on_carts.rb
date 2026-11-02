# Visitor carts now live in the session cookie (VisitorCart), so saved carts
# always belong to a user. Old visitor carts in the database are removed.
class RequireUserOnCarts < ActiveRecord::Migration[8.1]
  def up
    execute "DELETE FROM cart_items WHERE cart_id IN (SELECT id FROM carts WHERE user_id IS NULL)"
    execute "DELETE FROM carts WHERE user_id IS NULL"
    change_column_null :carts, :user_id, false
  end

  def down
    change_column_null :carts, :user_id, true
  end
end

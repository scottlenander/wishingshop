class AddNamesToUsers < ActiveRecord::Migration[8.1]
  class MigrationUser < ActiveRecord::Base
    self.table_name = "users"
  end

  def up
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string

    # Existing users get a first name from their email ("alice@..." -> "Alice")
    # and a placeholder last name, so the columns can be required. Admins can
    # correct them on the Users page.
    MigrationUser.find_each do |user|
      user.update_columns(first_name: user.email_address.split("@").first.capitalize, last_name: "User")
    end

    change_column_null :users, :first_name, false
    change_column_null :users, :last_name, false
  end

  def down
    remove_column :users, :first_name
    remove_column :users, :last_name
  end
end

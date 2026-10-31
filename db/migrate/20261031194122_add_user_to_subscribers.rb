class AddUserToSubscribers < ActiveRecord::Migration[8.1]
  def up
    add_reference :subscribers, :user, null: true, foreign_key: true

    # Link existing subscriptions to the account with the same email.
    execute <<~SQL
      UPDATE subscribers
      SET user_id = (SELECT users.id FROM users WHERE users.email_address = subscribers.email)
    SQL
  end

  def down
    remove_reference :subscribers, :user, foreign_key: true
  end
end

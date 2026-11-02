class CreateAnnouncements < ActiveRecord::Migration[8.1]
  def change
    create_table :announcements do |t|
      t.string :kind, null: false, default: "general"
      t.string :title, null: false
      t.text :body
      t.datetime :starts_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.datetime :ends_at
      t.integer :position, null: false, default: 0

      t.timestamps
    end
    add_index :announcements, %i[ starts_at ends_at ]
  end
end

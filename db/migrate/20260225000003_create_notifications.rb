# frozen_string_literal: true

class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.string :type, null: false, index: true
      t.references :subject, polymorphic: true, index: true
      t.string :title, null: false
      t.text :body
      t.datetime :read_at
      t.json :metadata

      t.timestamps
    end

    add_index :notifications, [:user_id, :read_at]
  end
end

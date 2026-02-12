# frozen_string_literal: true

class CreateMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :messages do |t|
      t.references :project, null: false, foreign_key: true
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.references :receiver, null: false, foreign_key: { to_table: :users }
      t.text :body, null: false

      t.timestamps
    end

    add_index :messages, [:project_id, :created_at]
    add_index :messages, [:sender_id, :receiver_id]
  end
end

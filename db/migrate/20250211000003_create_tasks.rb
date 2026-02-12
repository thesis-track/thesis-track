# frozen_string_literal: true

class CreateTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :tasks do |t|
      t.references :project, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.date :deadline
      t.string :status, null: false, default: "pending"

      t.timestamps
    end

    add_index :tasks, [:project_id, :status]
    add_index :tasks, :deadline
  end
end

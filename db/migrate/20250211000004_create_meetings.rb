# frozen_string_literal: true

class CreateMeetings < ActiveRecord::Migration[8.0]
  def change
    create_table :meetings do |t|
      t.references :project, null: false, foreign_key: true
      t.string :title, null: false
      t.text :agenda
      t.datetime :scheduled_at, null: false
      t.string :location

      t.timestamps
    end

    add_index :meetings, [:project_id, :scheduled_at]
  end
end

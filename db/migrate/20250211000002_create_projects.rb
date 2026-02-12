# frozen_string_literal: true

class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.references :student, null: false, foreign_key: { to_table: :users }, index: { unique: true }
      t.string :title, null: false
      t.text :description

      t.timestamps
    end
  end
end

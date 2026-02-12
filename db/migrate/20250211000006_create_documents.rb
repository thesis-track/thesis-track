# frozen_string_literal: true

class CreateDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :documents do |t|
      t.references :project, null: false, foreign_key: true
      t.string :title, null: false

      t.timestamps
    end
  end
end

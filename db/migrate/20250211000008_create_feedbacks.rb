# frozen_string_literal: true

class CreateFeedbacks < ActiveRecord::Migration[8.0]
  def change
    create_table :feedbacks do |t|
      t.references :project, null: false, foreign_key: true
      t.references :document_version, null: true, foreign_key: true
      t.string :section_name, null: false
      t.text :comments, null: false
      t.string :implementation_status, null: false, default: "pending"

      t.timestamps
    end

    add_index :feedbacks, [:project_id, :created_at]
    add_index :feedbacks, :implementation_status
  end
end
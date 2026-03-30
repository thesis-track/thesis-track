class AddStructuredFieldsToFeedbacks < ActiveRecord::Migration[8.1]
  def change
    add_column :feedbacks, :strengths, :text
    add_column :feedbacks, :areas_for_improvement, :text
    add_column :feedbacks, :required_actions, :text
    add_column :feedbacks, :priority_level, :string
    add_column :feedbacks, :approval_status, :string
  end
end

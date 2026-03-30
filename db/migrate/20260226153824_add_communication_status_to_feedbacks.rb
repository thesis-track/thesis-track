class AddCommunicationStatusToFeedbacks < ActiveRecord::Migration[8.1]
  def change
    add_column :feedbacks, :status, :string, default: "sent", null: false
    add_column :feedbacks, :acknowledged_at, :datetime
    add_column :feedbacks, :clarification_status, :string, default: "clear", null: false
  end
end

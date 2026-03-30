class AddCommunicationStatusToMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :status, :string, default: "sent", null: false
    add_column :messages, :acknowledged_at, :datetime
    add_column :messages, :blocking_issue, :boolean, default: false, null: false
  end
end

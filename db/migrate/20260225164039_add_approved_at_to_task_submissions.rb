class AddApprovedAtToTaskSubmissions < ActiveRecord::Migration[8.1]
  def change
    add_column :task_submissions, :approved_at, :datetime
  end
end

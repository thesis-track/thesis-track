class CreateTaskSubmissions < ActiveRecord::Migration[8.1]
  def change
    create_table :task_submissions do |t|
      t.references :task, null: false, foreign_key: true, index: { unique: true }
      t.text :notes
      t.text :supervisor_feedback
      t.datetime :submitted_at

      t.timestamps
    end
  end
end

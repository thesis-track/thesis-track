class CreateWeeklyProgressUpdates < ActiveRecord::Migration[8.1]
  def change
    create_table :weekly_progress_updates do |t|
      t.references :project, null: false, foreign_key: true
      t.date :week_start
      t.text :completed
      t.text :next_plan
      t.text :blockers
      t.string :status
      t.datetime :reviewed_at

      t.timestamps
    end
  end
end

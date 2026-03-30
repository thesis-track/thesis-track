class CreateProjectPhases < ActiveRecord::Migration[8.1]
  def change
    create_table :project_phases do |t|
      t.references :project, null: false, foreign_key: true
      t.string :phase_key
      t.datetime :completed_at

      t.timestamps
    end
    add_index :project_phases, [:project_id, :phase_key], unique: true
  end
end

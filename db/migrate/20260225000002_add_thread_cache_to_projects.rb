# frozen_string_literal: true

class AddThreadCacheToProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :last_message_at, :datetime
    add_column :projects, :last_message_by_id, :integer
    add_index :projects, :last_message_at
    add_index :projects, :last_message_by_id
  end
end

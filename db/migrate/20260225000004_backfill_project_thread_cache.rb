# frozen_string_literal: true

class BackfillProjectThreadCache < ActiveRecord::Migration[8.1]
  def up
    Project.find_each do |project|
      last_msg = project.messages.order(created_at: :asc).last
      if last_msg
        project.update_columns(
          last_message_at: last_msg.created_at,
          last_message_by_id: last_msg.sender_id
        )
      end
    end
  end

  def down
    Project.update_all(last_message_at: nil, last_message_by_id: nil)
  end
end

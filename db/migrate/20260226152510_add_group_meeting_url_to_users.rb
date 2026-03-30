class AddGroupMeetingUrlToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :group_meeting_url, :string
  end
end

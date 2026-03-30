# frozen_string_literal: true

class NoReplyReminderJob < ApplicationJob
  queue_as :default

  def perform
    threshold = AlertSettings.no_reply_reminder_days
    cutoff = threshold.days.ago

    Project.find_each do |project|
      last_msg = project.messages.ordered.last
      next if last_msg.blank?

      next if last_msg.created_at >= cutoff

      # Remind the receiver (the one who should reply)
      recipient = last_msg.receiver

      next if Notification::NoReplyReminder
        .where(user: recipient, subject: project)
        .where("created_at >= ?", 1.day.ago)
        .exists?

      Notification::NoReplyReminder.create!(
        user: recipient,
        subject: project,
        title: "Reminder: reply to #{last_msg.sender.name}",
        body: "You haven't replied to the message in #{project.title} for over #{threshold} days.",
        metadata: { project_id: project.id, message_id: last_msg.id }
      )
    end
  end
end
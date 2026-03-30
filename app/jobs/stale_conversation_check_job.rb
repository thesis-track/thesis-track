# frozen_string_literal: true

class StaleConversationCheckJob < ApplicationJob
  queue_as :default

  def perform
    threshold = AlertSettings.stale_threshold_days
    cutoff = threshold.days.ago

    Project.find_each do |project|
      last_at = project.last_message_at || project.messages.maximum(:created_at)
      next if last_at.blank? || last_at >= cutoff

      [project.student, project.student.supervisor].compact.each do |user|
        next if Notification::StaleConversation
          .where(user: user, subject: project)
          .where("created_at >= ?", 1.day.ago)
          .exists?

        Notification::StaleConversation.create!(
          user: user,
          subject: project,
          title: "Stale conversation",
          body: "No message in the thread for #{project.title} in over #{threshold} days.",
          metadata: { project_id: project.id, last_message_at: last_at.iso8601 }
        )
      end
    end
  end
end

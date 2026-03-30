# frozen_string_literal: true

class DeadlineReminderJob < ApplicationJob
  queue_as :default

  def perform
    AlertSettings.deadline_alert_days.each do |days_ahead|
      date = days_ahead.days.from_now.to_date
      Task.pending
        .where(deadline: date)
        .includes(project: :student)
        .find_each do |task|
        project = task.project
        student = project.student

        next if Notification::DeadlineReminder
          .where(user: student, subject: task)
          .where("created_at >= ?", 1.day.ago)
          .exists?

        Notification::DeadlineReminder.create!(
          user: student,
          subject: task,
          title: "Deadline in #{days_ahead} day#{'s' if days_ahead != 1}",
          body: "Task \"#{task.title}\" is due #{task.deadline.strftime('%B %d, %Y')}.",
          metadata: { task_id: task.id, project_id: project.id, deadline: task.deadline.iso8601 }
        )
      end
    end
  end
end

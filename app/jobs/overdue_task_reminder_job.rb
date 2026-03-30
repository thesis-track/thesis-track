# frozen_string_literal: true

class OverdueTaskReminderJob < ApplicationJob
  queue_as :default

  def perform
    Task.overdue
      .includes(project: :student)
      .find_each do |task|
      student = task.project.student

      next if Notification::OverdueTask
        .where(user: student, subject: task)
        .where("created_at >= ?", 1.day.ago)
        .exists?

      Notification::OverdueTask.create!(
        user: student,
        subject: task,
        title: "Overdue task",
        body: "Task \"#{task.title}\" was due #{task.deadline.strftime('%B %d, %Y')}.",
        metadata: { task_id: task.id, project_id: task.project_id, deadline: task.deadline.iso8601 }
      )
    end
  end
end
# frozen_string_literal: true

class TaskSubmission < ApplicationRecord
  belongs_to :task
  has_one_attached :attachment

  validates :task_id, uniqueness: true

  after_create :mark_task_completed_and_notify_supervisor

  def approved?
    approved_at.present?
  end

  private

  def mark_task_completed_and_notify_supervisor
    task.update!(status: "completed")
    supervisor = task.project.student.supervisor
    return unless supervisor

    Notification::TaskSubmission.create!(
      user: supervisor,
      subject: task,
      title: "#{task.project.student.name} submitted: #{task.title}",
      body: notes.present? ? notes.to_s.truncate(120) : "No notes provided.",
      metadata: { project_id: task.project_id, task_id: task.id, task_submission_id: id }
    )
  end
end

# frozen_string_literal: true

class DashboardController < ApplicationController
  def show
    if current_user.supervisor?
      set_supervisor_dashboard_data
      render :supervisor
    else
      render :student
    end
  end

  private

  def set_supervisor_dashboard_data
    @students = current_user.students.includes(project: [:tasks, :meetings, :feedbacks, :messages])
    projects = Project.where(student_id: current_user.student_ids)

    @total_students = @students.count
    @students_at_risk = projects.count { |p| p.supervision_status != :on_track }
    @pending_feedback_count = Feedback.joins(:project).where(projects: { student_id: current_user.student_ids }).pending_implementation.count
    @upcoming_meetings_this_week = Meeting.joins(:project).where(projects: { student_id: current_user.student_ids }).where("scheduled_at >= ? AND scheduled_at <= ?", Time.current, 1.week.from_now).count
    @overdue_tasks = Task.joins(:project).where(projects: { student_id: current_user.student_ids }).merge(Task.overdue).includes(project: :student).order("tasks.deadline ASC").limit(20)
  end
end

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

  def update_meeting_link
    redirect_to dashboard_path, alert: "Access denied." and return unless current_user.supervisor?
    if current_user.update(meeting_link_params)
      redirect_to dashboard_path, notice: current_user.group_meeting_url.present? ? "Meeting link saved." : "Meeting link removed."
    else
      redirect_to dashboard_path, alert: current_user.errors.full_messages.to_sentence
    end
  end

  private

  def meeting_link_params
    params.require(:user).permit(:group_meeting_url)
  end

  def set_supervisor_dashboard_data
    @students = current_user.students.includes(project: [:tasks, :meetings, :feedbacks, :messages, :project_phases])
    projects = Project.where(student_id: current_user.student_ids).to_a

    @total_students = @students.count
    @students_at_risk = projects.count { |p| %i[high medium].include?(p.risk_level) }
    @pending_feedback_count = Feedback.joins(:project).where(projects: { student_id: current_user.student_ids }).pending_implementation.count
    @upcoming_meetings_this_week = Meeting.joins(:project).where(projects: { student_id: current_user.student_ids }).where("scheduled_at >= ? AND scheduled_at <= ?", Time.current, 1.week.from_now).count
    @overdue_tasks = Task.joins(:project).where(projects: { student_id: current_user.student_ids }).merge(Task.overdue).includes(project: :student).order("tasks.deadline ASC").limit(20)

    # Submissions pending supervisor approval (completed but not approved)
    @submissions_pending_approval = TaskSubmission.joins(task: :project)
      .where(projects: { student_id: current_user.student_ids })
      .where(approved_at: nil)
      .includes(task: { project: :student })
      .order(created_at: :desc)

    # Risk dashboard: student, current phase, last activity, next deadline, health score, risk level
    @risk_table = @students.filter_map do |student|
      proj = student.project
      next nil unless proj&.persisted?

      {
        student: student,
        project: proj,
        current_phase: proj.current_phase_name,
        last_activity_at: proj.last_activity_at,
        next_deadline: proj.next_deadline,
        risk_level: proj.risk_level
      }
    end
  end
end

# frozen_string_literal: true

class TaskSubmissionsController < ApplicationController
  before_action :set_project
  before_action :set_task
  before_action :set_task_submission, only: %i[update approve]

  def create
    redirect_to project_tasks_path(@project), alert: "You already submitted this task." and return if @task.task_submission.present?
    redirect_to project_task_path(@project, @task), alert: "Only the student can submit this task." and return unless @task.project.student_id == current_user.id

    @submission = @task.build_task_submission(task_submission_params)
    @submission.submitted_at = Time.current
    if @submission.save
      redirect_to project_task_path(@project, @task), notice: "Task submitted. It is now marked completed and your supervisor has been notified."
    else
      redirect_to project_task_path(@project, @task), alert: @submission.errors.full_messages.to_sentence
    end
  end

  def update
    redirect_to project_task_path(@project, @task), alert: "Only the supervisor can add feedback." and return unless current_user.supervisor?
    return unless project_visible?(@project)

    if @task_submission.update(task_submission_feedback_params)
      redirect_to project_task_path(@project, @task), notice: "Feedback saved."
    else
      redirect_to project_task_path(@project, @task), alert: @task_submission.errors.full_messages.to_sentence
    end
  end

  def approve
    redirect_to project_task_path(@project, @task), alert: "Only the supervisor can approve." and return unless current_user.supervisor?
    return unless project_visible?(@project)
    redirect_to project_task_path(@project, @task), alert: "No submission found." and return unless @task_submission

    @task_submission.update!(approved_at: Time.current)
    redirect_to project_task_path(@project, @task), notice: "Task approved."
  end

  private

  def set_project
    @project = find_visible_project(params[:project_id])
    redirect_to root_path, alert: "Project not found." unless @project
  end

  def set_task
    @task = @project.tasks.find(params[:task_id])
  end

  def set_task_submission
    @task_submission = @task.task_submission
    redirect_to project_task_path(@project, @task), alert: "No submission found." unless @task_submission
  end

  def task_submission_params
    params.require(:task_submission).permit(:notes, :attachment)
  end

  def task_submission_feedback_params
    params.require(:task_submission).permit(:supervisor_feedback)
  end
end

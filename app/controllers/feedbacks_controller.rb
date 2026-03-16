# frozen_string_literal: true

class FeedbacksController < ApplicationController
  before_action :set_project
  before_action :set_feedback, only: %i[show edit update destroy acknowledge]

  def index
    @feedbacks = @project.feedbacks.recent
    @feedbacks = @feedbacks.pending_implementation if params[:status] == "pending"
    # Supervisor feedback on task submissions (for students to see on Feedback tab)
    @submission_feedbacks = TaskSubmission.joins(:task)
      .where(tasks: { project_id: @project.id })
      .where.not(supervisor_feedback: [nil, ""])
      .order(updated_at: :desc)
      .includes(:task)
  end

  def show
  end

  def new
    @feedback = @project.feedbacks.build
  end

  def create
    @feedback = @project.feedbacks.build(feedback_params)
    @feedback.section_name = "Feedback" if @feedback.section_name.blank?
    if @feedback.save
      redirect_to project_feedbacks_path(@project), notice: "Feedback added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @feedback.update(feedback_params)
      redirect_to project_feedbacks_path(@project), notice: "Feedback updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @feedback.destroy
    redirect_to project_feedbacks_path(@project), notice: "Feedback removed."
  end

  def acknowledge
    if @feedback.acknowledge!(by: current_user)
      redirect_to project_feedback_path(@project, @feedback), notice: "Feedback acknowledged."
    else
      redirect_to project_feedback_path(@project, @feedback), alert: "You cannot acknowledge this feedback."
    end
  end

  private

  def set_project
    @project = find_visible_project(params[:project_id])
    redirect_to root_path, alert: "Project not found." unless @project
  end

  def set_feedback
    @feedback = @project.feedbacks.find(params[:id])
  end

  def feedback_params
    permitted = [
      :section_name, :comments, :implementation_status, :document_version_id,
      :strengths, :areas_for_improvement, :required_actions, :priority_level, :approval_status,
      :clarification_status
    ]
    p = params.require(:feedback).permit(permitted)
    # Student may only update clarification_status; supervisor can update all
    p = p.slice(:clarification_status) if current_user&.student?
    p.slice(*Feedback.column_names.map(&:to_sym))
  end
end
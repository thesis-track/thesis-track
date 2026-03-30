# frozen_string_literal: true

class WeeklyProgressUpdatesController < ApplicationController
  before_action :set_project
  before_action :set_update, only: %i[update]

  def index
    @updates = @project.weekly_progress_updates.recent_first
  end

  def new
    @update = @project.weekly_progress_updates.build(week_start: current_week_start)
    redirect_to project_weekly_progress_updates_path(@project), alert: "Only the student can submit progress." and return if current_user.supervisor?
  end

  def create
    redirect_to project_weekly_progress_updates_path(@project), alert: "Only the student can submit progress." and return unless current_user.student? && @project.student_id == current_user.id
    @update = @project.weekly_progress_updates.build(update_params)
    @update.week_start ||= current_week_start
    if @update.save
      redirect_to project_weekly_progress_updates_path(@project), notice: "Progress submitted."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    redirect_to project_weekly_progress_updates_path(@project), alert: "Only the supervisor can mark status." and return unless current_user.supervisor?
    if @update.update(update_status_params)
      redirect_to project_weekly_progress_updates_path(@project), notice: "Status updated."
    else
      redirect_to project_weekly_progress_updates_path(@project), alert: @update.errors.full_messages.to_sentence
    end
  end

  private

  def set_project
    @project = find_visible_project(params[:project_id])
    redirect_to root_path, alert: "Project not found." unless @project
  end

  def set_update
    @update = @project.weekly_progress_updates.find(params[:id])
  end

  def update_params
    params.require(:weekly_progress_update).permit(:week_start, :completed, :next_plan, :blockers)
  end

  def update_status_params
    { status: params[:weekly_progress_update][:status], reviewed_at: Time.current }
  end

  def current_week_start
    Date.current.beginning_of_week(:monday)
  end
end

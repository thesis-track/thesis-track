# frozen_string_literal: true

class MeetingsController < ApplicationController
  before_action :set_project
  before_action :set_meeting, only: %i[show edit update destroy]

  def index
    @meetings = @project.meetings.upcoming
    @past_meetings = @project.meetings.past.limit(10)
  end

  def show
  end

  def new
    @meeting = @project.meetings.build
  end

  def create
    @meeting = @project.meetings.build(meeting_params)
    if @meeting.save
      redirect_to project_meetings_path(@project), notice: "Meeting scheduled successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @meeting.update(meeting_params)
      redirect_to project_meetings_path(@project), notice: "Meeting updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @meeting.destroy
    redirect_to project_meetings_path(@project), notice: "Meeting cancelled."
  end

  private

  def set_project
    @project = find_visible_project(params[:project_id])
    redirect_to root_path, alert: "Project not found." unless @project
  end

  def set_meeting
    @meeting = @project.meetings.find(params[:id])
  end

  def meeting_params
    params.require(:meeting).permit(:title, :agenda, :scheduled_at, :location)
  end
end

# frozen_string_literal: true

class FeedbacksController < ApplicationController
  before_action :set_project
  before_action :set_feedback, only: %i[show edit update destroy]

  def index
    @feedbacks = @project.feedbacks.recent
    @feedbacks = @feedbacks.pending_implementation if params[:status] == "pending"
  end

  def show
  end

  def new
    @feedback = @project.feedbacks.build
    @document_versions = @project.documents.flat_map { |d| d.document_versions.order(version_number: :desc).limit(5) }
  end

  def create
    @feedback = @project.feedbacks.build(feedback_params)
    if @feedback.save
      redirect_to project_feedbacks_path(@project), notice: "Feedback added."
    else
      @document_versions = @project.documents.flat_map { |d| d.document_versions.order(version_number: :desc).limit(5) }
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @document_versions = @project.documents.flat_map { |d| d.document_versions.order(version_number: :desc).limit(5) }
  end

  def update
    if @feedback.update(feedback_params)
      redirect_to project_feedbacks_path(@project), notice: "Feedback updated."
    else
      @document_versions = @project.documents.flat_map { |d| d.document_versions.order(version_number: :desc).limit(5) }
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @feedback.destroy
    redirect_to project_feedbacks_path(@project), notice: "Feedback removed."
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
    params.require(:feedback).permit(:section_name, :comments, :implementation_status, :document_version_id)
  end
end
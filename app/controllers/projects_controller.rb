# frozen_string_literal: true

class ProjectsController < ApplicationController
  before_action :set_project, only: %i[show edit update]

  def index
    if current_user.supervisor?
      @projects = Project.where(student_id: current_user.student_ids).includes(:student).order(updated_at: :desc)
    else
      if current_user.project
        redirect_to project_path(current_user.project)
      else
        redirect_to get_started_path
      end
    end
  end

  def show
    redirect_to dashboard_path, alert: "Project not found." unless @project
  end

  def new
    redirect_to dashboard_path, alert: "You already have a project." if current_user.project.present?
    @project = Project.new
  end

  def create
    redirect_to dashboard_path, alert: "You already have a project." and return if current_user.project.present?
    @project = current_user.build_project(project_params)
    if @project.save
      redirect_to project_path(@project), notice: "Project created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    redirect_to dashboard_path, alert: "Project not found." unless @project
  end

  def update
    return redirect_to dashboard_path, alert: "Project not found." unless @project
    if @project.update(project_params)
      redirect_to project_path(@project), notice: "Project updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_project
    @project = find_visible_project(params[:id])
  end

  def project_params
    params.require(:project).permit(:title, :description)
  end
end

# frozen_string_literal: true

class OnboardingController < ApplicationController
  before_action :require_student_without_project

  def show
    @project = current_user.build_project
  end

  def create
    @project = current_user.build_project(project_params)
    if @project.save
      redirect_to dashboard_path, notice: "Welcome! Your project is set up. Head to your dashboard to get started."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def require_student_without_project
    return if current_user.student? && current_user.project.blank?
    redirect_to dashboard_path
  end

  def project_params
    params.require(:project).permit(:title, :description)
  end
end
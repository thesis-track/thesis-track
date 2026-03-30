# frozen_string_literal: true

class ConversationsController < ApplicationController
  def index
    if current_user.supervisor?
      @projects = Project.where(student_id: current_user.student_ids)
        .includes(:student)
        .order(last_message_at: :desc, updated_at: :desc)
      render :index
    elsif current_user.project.present? && current_user.project.persisted?
      redirect_to project_messages_path(current_user.project)
    else
      redirect_to get_started_path, notice: "Create a project to use messages."
    end
  end
end

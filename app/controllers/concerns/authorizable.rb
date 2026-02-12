# frozen_string_literal: true

module Authorizable
  extend ActiveSupport::Concern

  def require_supervisor
    return if current_user&.supervisor?
    redirect_to root_path, alert: "Access denied. Supervisor only."
  end

  def require_student
    return if current_user&.student?
    redirect_to root_path, alert: "Access denied. Student only."
  end

  def project_visible?(project)
    return false unless current_user
    return true if current_user.supervisor? && current_user.student_ids.include?(project.student_id)
    return true if current_user.student? && project.student_id == current_user.id
    false
  end

  def find_visible_project(id)
    project = Project.find_by(id: id)
    return nil unless project && project_visible?(project)
    project
  end
end

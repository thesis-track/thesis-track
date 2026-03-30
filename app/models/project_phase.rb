# frozen_string_literal: true

class ProjectPhase < ApplicationRecord
  belongs_to :project

  validates :phase_key, presence: true, inclusion: { in: Project::PHASE_KEYS }
  validates :phase_key, uniqueness: { scope: :project_id }
end

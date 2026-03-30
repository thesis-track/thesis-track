# frozen_string_literal: true

class WeeklyProgressUpdate < ApplicationRecord
  STATUSES = %w[pending reviewed needs_follow_up].freeze

  belongs_to :project

  validates :week_start, presence: true
  validates :week_start, uniqueness: { scope: :project_id }
  validates :status, inclusion: { in: STATUSES }, allow_blank: true

  scope :recent_first, -> { order(week_start: :desc) }
end

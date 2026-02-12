# frozen_string_literal: true

class Feedback < ApplicationRecord
  IMPLEMENTATION_STATUSES = %w[pending implemented].freeze

  belongs_to :project
  belongs_to :document_version, optional: true

  validates :section_name, presence: true
  validates :comments, presence: true
  validates :implementation_status, presence: true, inclusion: { in: IMPLEMENTATION_STATUSES }

  scope :pending_implementation, -> { where(implementation_status: "pending") }
  scope :implemented, -> { where(implementation_status: "implemented") }
  scope :recent, -> { order(created_at: :desc) }
end
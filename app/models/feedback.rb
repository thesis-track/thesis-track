# frozen_string_literal: true

class Feedback < ApplicationRecord
  STATUSES = %w[sent seen acknowledged responded].freeze
  CLARIFICATION_STATUSES = %w[clear needs_clarification].freeze
  IMPLEMENTATION_STATUSES = %w[pending implemented].freeze
  PRIORITY_LEVELS = %w[low medium high].freeze
  APPROVAL_STATUSES = %w[approved revision_required].freeze

  belongs_to :project
  belongs_to :document_version, optional: true

  validates :section_name, presence: true
  validates :comments, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :clarification_status, inclusion: { in: CLARIFICATION_STATUSES }
  validates :implementation_status, presence: true, inclusion: { in: IMPLEMENTATION_STATUSES }
  validates :priority_level, inclusion: { in: PRIORITY_LEVELS }, allow_blank: true
  validates :approval_status, inclusion: { in: APPROVAL_STATUSES }, allow_blank: true

  scope :pending_implementation, -> { where(implementation_status: "pending") }
  scope :implemented, -> { where(implementation_status: "implemented") }
  scope :recent, -> { order(created_at: :desc) }
  scope :needs_clarification, -> { where(clarification_status: "needs_clarification") }

  after_save :mark_responded_after_supervisor_edit, if: :supervisor_responded?

  # Only the project's supervisor can acknowledge. Records timestamp.
  def acknowledge!(by:)
    return false unless project.student.supervisor_id == by.id
    return false if status.in?(%w[acknowledged responded])

    update!(status: "acknowledged", acknowledged_at: Time.current)
  end

  def acknowledged?
    status.in?(%w[acknowledged responded])
  end

  def needs_clarification?
    clarification_status == "needs_clarification"
  end

  # Response time: seconds from created_at to acknowledged_at (nil if not acknowledged)
  def seconds_to_acknowledgement
    return nil unless acknowledged_at
    acknowledged_at.to_i - created_at.to_i
  end

  def hours_to_acknowledgement
    return nil unless seconds_to_acknowledgement
    (seconds_to_acknowledgement / 3600.0).round(1)
  end

  private

  def supervisor_responded?
    (saved_change_to_comments? || saved_change_to_implementation_status?) && status == "acknowledged"
  end

  def mark_responded_after_supervisor_edit
    update_column(:status, "responded")
  end
end
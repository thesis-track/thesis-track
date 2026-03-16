# frozen_string_literal: true

class Task < ApplicationRecord
  STATUSES = %w[pending completed].freeze

  belongs_to :project
  has_one :task_submission, dependent: :destroy

  validates :title, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: "pending") }
  scope :completed, -> { where(status: "completed") }
  scope :overdue, -> { pending.where("deadline < ?", Time.zone.today) }
  scope :by_deadline, -> { order(Arel.sql("deadline IS NULL, deadline ASC")) }
  scope :recent_first, -> { order(created_at: :desc) }

  def pending?
    status == "pending"
  end

  def completed?
    status == "completed"
  end

  def supervisor_approved?
    task_submission&.approved?
  end

  def overdue?
    deadline.present? && status == "pending" && deadline < Time.zone.today
  end
end

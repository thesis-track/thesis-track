# frozen_string_literal: true

class Notification < ApplicationRecord
  TYPES = %w[
    Notification::DeadlineReminder
    Notification::NoReplyReminder
    Notification::StaleConversation
    Notification::OverdueTask
    Notification::NewMessage
    Notification::TaskSubmission
  ].freeze

  belongs_to :user
  belongs_to :subject, polymorphic: true, optional: true

  validates :type, inclusion: { in: TYPES }
  validates :title, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent_first, -> { order(created_at: :desc) }

  def read?
    read_at.present?
  end

  def mark_read!
    update!(read_at: read_at || Time.current)
  end
end

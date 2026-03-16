# frozen_string_literal: true

class Message < ApplicationRecord
  STATUSES = %w[sent seen acknowledged responded].freeze

  belongs_to :project
  belongs_to :sender, class_name: "User"
  belongs_to :receiver, class_name: "User"

  has_many_attached :attachments

  validates :body, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :ordered, -> { order(created_at: :asc) }
  # Case-insensitive search; works with both SQLite (no ILIKE) and PostgreSQL
  scope :search_body, ->(query) {
    pattern = "%#{sanitize_sql_like(query.to_s).downcase}%"
    where("LOWER(body) LIKE ?", pattern)
  }
  scope :unread_by, ->(user) { where(receiver_id: user.id, read_at: nil) }
  scope :awaiting_receiver_response, -> { where(status: %w[sent seen acknowledged]) }
  scope :blocking_unresponded, -> { where(blocking_issue: true).where.not(status: "responded") }

  after_commit :update_project_thread_cache, on: [:create, :destroy]
  after_commit :notify_receiver, on: :create
  after_commit :mark_preceding_as_responded, on: :create

  def read?
    read_at.present?
  end

  def mark_read!
    updates = { read_at: read_at || Time.current }
    updates[:status] = "seen" if status == "sent"
    update!(updates)
  end

  def acknowledge!(by:)
    return false unless receiver_id == by.id
    return false if status.in?(%w[acknowledged responded])

    update!(status: "acknowledged", acknowledged_at: Time.current)
  end

  def acknowledged?
    status.in?(%w[acknowledged responded])
  end

  def responded?
    status == "responded"
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

  def mark_preceding_as_responded
    project.messages
      .where(receiver_id: sender_id)
      .where(status: %w[sent seen acknowledged])
      .update_all(status: "responded")
  end

  def update_project_thread_cache
    project.update_thread_cache!
  end

  def notify_receiver
    return if receiver_id == sender_id # don't notify yourself

    Notification::NewMessage.create!(
      user: receiver,
      subject: self,
      title: "New message from #{sender.name}",
      body: truncate_body_for_notification,
      metadata: { project_id: project.id, message_id: id }
    )
  end

  def truncate_body_for_notification
    return "" if body.blank?
    body.gsub(/\s+/, " ").strip.truncate(120)
  end
end

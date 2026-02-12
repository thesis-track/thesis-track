# frozen_string_literal: true

class Project < ApplicationRecord
  INACTIVITY_DAYS_AT_RISK = 14
  MEETING_WINDOW_DAYS = 30

  belongs_to :student, class_name: "User"
  has_many :tasks, dependent: :destroy
  has_many :meetings, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :documents, dependent: :destroy
  has_many :feedbacks, dependent: :destroy
  has_many :document_versions, through: :documents

  validates :title, presence: true

  def progress_percentage
    return 0 if tasks.empty?
    completed = tasks.where(status: "completed").count
    ((completed.to_f / tasks.count) * 100).round
  end

  def overdue_tasks
    tasks.where(status: "pending").where("deadline < ?", Time.zone.today)
  end

  def overdue_tasks_count
    overdue_tasks.count
  end

  # Last activity: most recent update across messages, tasks, feedbacks, document_versions, meetings
  def last_activity_at
    timestamps = [
      messages.maximum(:updated_at),
      tasks.maximum(:updated_at),
      feedbacks.maximum(:updated_at),
      document_versions.maximum(:updated_at),
      meetings.maximum(:updated_at),
      updated_at
    ].compact
    timestamps.max
  end

  def last_message_at
    messages.maximum(:created_at)
  end

  # Supervision status: :on_track, :at_risk, :behind
  def supervision_status
    return :on_track if tasks.empty? && meetings.none? && messages.none?
    return :behind if overdue_tasks_count.positive?
    last = last_activity_at
    no_recent_activity = last && last < INACTIVITY_DAYS_AT_RISK.days.ago
    next_meeting = meetings.upcoming.first
    no_meeting_soon = next_meeting.nil? || next_meeting.scheduled_at > MEETING_WINDOW_DAYS.days.from_now
    return :at_risk if no_recent_activity || no_meeting_soon
    :on_track
  end

  def next_deadline
    tasks.pending.where("deadline >= ?", Time.zone.today).order(:deadline).limit(1).pick(:deadline)
  end

  # Supervision health score 0–100 with breakdown (for research-driven metric)
  def supervision_health_score
    breakdown = supervision_health_breakdown
    (breakdown[:tasks] * 0.4 + breakdown[:feedback] * 0.3 + breakdown[:meetings] * 0.3).round
  end

  def supervision_health_breakdown
    task_pct = tasks.empty? ? 100 : progress_percentage
    total_fb = feedbacks.count
    implemented_fb = total_fb.zero? ? 100 : (feedbacks.implemented.count.to_f / total_fb * 100).round
    has_recent_or_upcoming_meeting = meetings.where(
      "(scheduled_at >= ? AND scheduled_at <= ?) OR (scheduled_at >= ? AND scheduled_at <= ?)",
      MEETING_WINDOW_DAYS.days.ago, Time.current, Time.current, MEETING_WINDOW_DAYS.days.from_now
    ).exists?
    meetings_pct = has_recent_or_upcoming_meeting ? 100 : 0
    {
      tasks: task_pct,
      feedback: implemented_fb,
      meetings: meetings_pct
    }
  end

  # Timeline phases (phase-based progression snapshot)
  def timeline_phases
    pct = progress_percentage
    [
      { name: "Proposal", threshold: 20, done: pct >= 20 },
      { name: "Research", threshold: 40, done: pct >= 40 },
      { name: "Development", threshold: 60, done: pct >= 60 },
      { name: "Testing", threshold: 80, done: pct >= 80 },
      { name: "Final Report", threshold: 100, done: pct >= 100 }
    ]
  end
end

# frozen_string_literal: true

class Project < ApplicationRecord
  INACTIVITY_DAYS_AT_RISK = 14
  MEETING_WINDOW_DAYS = 30
  THREAD_STATUS_STALE_DAYS = 5
  HEALTH_NO_ACTIVITY_DAYS = 14

  # Structured phases: must be completed in order; completion timestamp logged.
  PHASES = [
    { key: "proposal", name: "Proposal" },
    { key: "implementation", name: "Implementation" },
    { key: "testing", name: "Testing" },
    { key: "writing", name: "Writing" },
    { key: "submission", name: "Submission" }
  ].freeze
  PHASE_KEYS = PHASES.map { |p| p[:key] }.freeze

  # Default FYP tasks created for every new project (supervisor can edit; students view only).
  DEFAULT_TASKS = [
    { title: "Project Proposal Form", deadline: "2026-09-29", description: "Prepare and submit the official Final Year Project proposal outlining the project title, objectives, research focus, and planned deliverables." },
    { title: "Submission of Ethics declarations", deadline: "2026-10-24", description: nil },
    { title: "Submission deadline for Ethics applications to S&E Ethics Committee", deadline: "2026-11-06", description: nil },
    { title: "Project Presentation", deadline: "2026-11-08", description: nil },
    { title: "Deadline for Interim Report", deadline: "2026-12-23", description: nil },
    { title: "Deadline for Draft Report (not graded)", deadline: "2027-03-19", description: nil },
    { title: "Final-submission-date for Product", deadline: "2027-04-21", description: nil },
    { title: "Showcase Day", deadline: "2027-04-27", description: nil },
    { title: "Final-submission-date for FYP Report", deadline: "2027-04-27", description: nil },
    { title: "Cut-off-date - FYP Product & FYP Report", deadline: "2027-05-01", description: nil }
  ].freeze

  after_create :create_default_tasks

  belongs_to :student, class_name: "User"
  belongs_to :last_message_by, class_name: "User", optional: true
  delegate :supervisor, to: :student, allow_nil: true
  has_many :tasks, dependent: :destroy
  has_many :meetings, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :documents, dependent: :destroy
  has_many :feedbacks, dependent: :destroy
  has_many :document_versions, through: :documents
  has_many :project_phases, dependent: :destroy
  has_many :weekly_progress_updates, dependent: :destroy

  validates :title, presence: true

  # Thread status: :awaiting_supervisor_reply | :awaiting_student_reply | :responded | :stale
  def thread_status
    last_at = last_message_at || messages.maximum(:created_at)
    return :responded if last_at.blank?

    stale_days = AlertSettings.stale_threshold_days
    return :stale if last_at.to_time < stale_days.days.ago

    last_sender = last_message_by.presence || messages.order(created_at: :desc).first&.sender
    return :responded unless last_sender

    if last_sender.supervisor?
      :awaiting_student_reply
    else
      :awaiting_supervisor_reply
    end
  end

  # Risk level for supervisor dashboard.
  # High: missed deadline OR no activity > 14 days OR unresponded blocking message
  # Medium: deadline within 5 days
  # Low: else
  def risk_level
    return :high if overdue_tasks_count.positive?
    return :high if messages.blocking_unresponded.exists?
    last_act = last_activity_at&.to_time
    return :high if last_act && last_act < HEALTH_NO_ACTIVITY_DAYS.days.ago

    next_dd = next_deadline
    if next_dd
      days_until = (next_dd.to_date - Time.zone.today).to_i
      return :medium if days_until <= 5 && days_until >= 0
    end
    :low
  end

  def unread_count_for(user)
    messages.where(receiver_id: user.id, read_at: nil).count
  end

  def thread_stale?
    last_at = last_message_at || messages.maximum(:created_at)
    return false if last_at.blank?
    last_at.to_time < AlertSettings.stale_threshold_days.days.ago
  end

  def update_thread_cache!
    last_msg = messages.ordered.last
    if last_msg
      update_columns(last_message_at: last_msg.created_at, last_message_by_id: last_msg.sender_id)
    else
      update_columns(last_message_at: nil, last_message_by_id: nil)
    end
  end

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

  # Activity-based flag for dashboard: no activity 10 days → yellow, 14 days → red
  def activity_flag
    last_act = last_activity_at&.to_time
    return nil if last_act.blank?

    days = (Time.current - last_act).to_i / 1.day
    return :red if days >= AlertSettings.no_activity_red_days
    return :yellow if days >= AlertSettings.no_activity_yellow_days
    nil
  end

  # --- Phase workflow ---
  def current_phase_key
    PHASE_KEYS.each do |key|
      return key unless phase_completed?(key)
    end
    "submission"
  end

  def current_phase_name
    PHASES.find { |p| p[:key] == current_phase_key }&.dig(:name) || "Submission"
  end

  def phase_completed?(phase_key)
    project_phases.find_by(phase_key: phase_key)&.completed_at.present?
  end

  def phase_completed_at(phase_key)
    project_phases.find_by(phase_key: phase_key)&.completed_at
  end

  # For phase list: array of { key:, name:, completed:, current:, completed_at: }
  def phase_progress_data
    phase_records = project_phases.index_by(&:phase_key)
    current_key = current_phase_key
    PHASES.map do |p|
      rec = phase_records[p[:key]]
      completed = rec&.completed_at.present?
      current = (current_key == p[:key])
      { key: p[:key], name: p[:name], completed: completed, current: current, completed_at: rec&.completed_at }
    end
  end

  def complete_phase!(phase_key)
    return false unless PHASE_KEYS.include?(phase_key)
    rec = project_phases.find_or_initialize_by(phase_key: phase_key)
    return true if rec.completed_at.present?
    rec.completed_at = Time.current
    rec.save!
  end

  # Timeline phases (legacy: percentage-based display can stay for backwards compat)
  def timeline_phases
    phase_progress_data.map { |p| { name: p[:name], done: p[:completed], current: p[:current] } }
  end

  # Integrated communication feed: messages + feedback in one chronological list (no disappearing threads).
  # Returns array of { at:, type: :message|:feedback, record: } sorted by at asc.
  def communication_feed_items(limit: 200)
    items = []
    messages.ordered.find_each { |m| items << { at: m.created_at, type: :message, record: m } }
    feedbacks.recent.each { |f| items << { at: f.created_at, type: :feedback, record: f } }
    items.sort_by { |h| h[:at].to_time }.last(limit)
  end

  # Activity log: document uploads, feedback, deadlines, phase completed, meetings.
  # Ordered "most recent first": past events reverse-chronological (most recent past at top), then future events soonest first.
  # Returns array of { at:, label:, type:, link_options: }.
  def activity_timeline(limit: 30)
    items = []

    feedbacks.find_each do |f|
      items << { at: f.created_at, label: "Feedback on #{f.section_name}", type: :feedback, link_options: [self, f] }
    end

    document_versions.includes(:document).find_each do |dv|
      items << { at: dv.created_at, label: "#{dv.document.title} #{dv.version_label} uploaded", type: :document, link_options: [self, dv.document] }
    end

    tasks.find_each do |t|
      if t.overdue?
        items << { at: t.deadline, label: "Deadline missed: #{t.title}", type: :deadline_missed, link_options: [self, t] }
      elsif t.deadline.present?
        items << { at: t.deadline, label: "Deadline: #{t.title}", type: :deadline, link_options: [self, t] }
      end
      if t.completed?
        items << { at: t.updated_at, label: "Task completed: #{t.title}", type: :task, link_options: [self, t] }
      end
    end

    project_phases.where.not(completed_at: nil).find_each do |pp|
      name = PHASES.find { |p| p[:key] == pp.phase_key }&.dig(:name) || pp.phase_key
      items << { at: pp.completed_at, label: "Phase completed: #{name}", type: :phase_completed, link_options: [self] }
    end

    meetings.find_each do |m|
      items << { at: m.scheduled_at, label: "Meeting: #{m.title}", type: :meeting, link_options: [self, m] }
    end

    now = Time.current
    past = items.select { |h| h[:at].present? && h[:at].to_time <= now }.sort_by { |h| h[:at].to_time }.reverse
    future = items.select { |h| h[:at].present? && h[:at].to_time > now }.sort_by { |h| h[:at].to_time }
    (past + future).first(limit)
  end

  private

  def create_default_tasks
    DEFAULT_TASKS.each do |attrs|
      tasks.create!(
        title: attrs[:title],
        description: attrs[:description],
        deadline: attrs[:deadline].present? ? Time.zone.parse(attrs[:deadline].to_s) : nil,
        status: "pending"
      )
    end
  end
end

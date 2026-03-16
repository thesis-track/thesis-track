# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable

  enum :role, { student: "student", supervisor: "supervisor" }, validate: true

  # Virtual attribute for sign-up: supervisor email (resolved to supervisor_id)
  attr_accessor :supervisor_email

  # As supervisor: students I supervise
  has_many :students, class_name: "User", foreign_key: :supervisor_id, dependent: :nullify
  belongs_to :supervisor, class_name: "User", optional: true

  # As student: my project
  has_one :project, foreign_key: :student_id, dependent: :destroy

  # Messages sent and received
  has_many :sent_messages, class_name: "Message", foreign_key: :sender_id, dependent: :destroy
  has_many :received_messages, class_name: "Message", foreign_key: :receiver_id, dependent: :destroy

  # Notifications
  has_many :notifications, dependent: :destroy

  # Profile picture
  has_one_attached :avatar

  validates :first_name, :last_name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :degree_programme, presence: true, if: :student?
  validates :department, presence: true, if: :supervisor?
  validate :student_must_have_supervisor
  validate :supervisor_email_must_exist, on: :create
  before_validation :assign_supervisor_from_email!, on: :create

  scope :supervisors, -> { where(role: :supervisor) }
  scope :students, -> { where(role: :student) }

  def name
    "#{first_name} #{last_name}".strip
  end

  def initials
    parts = [first_name, last_name].compact.map { |s| s.strip[0] }.reject(&:blank?)
    parts.any? ? parts.join.upcase : email[0].to_s.upcase
  end

  # Unread count for nav: at least as many as unread messages (covers messages that never got a notification)
  def unread_notification_count
    n = notifications.unread.count
    m = received_messages.where(read_at: nil).count
    [n, m].max
  end

  # Create missing NewMessage notifications for unread received messages (e.g. from before the feature existed)
  def ensure_notifications_for_unread_messages!
    received_messages.where(read_at: nil).find_each do |msg|
      next if notifications.where(type: "Notification::NewMessage", subject_type: "Message", subject_id: msg.id).exists?

      Notification::NewMessage.create!(
        user: self,
        subject: msg,
        title: "New message from #{msg.sender.name}",
        body: msg.body.to_s.gsub(/\s+/, " ").strip.truncate(120),
        metadata: { project_id: msg.project_id, message_id: msg.id }
      )
    end
  end

  def supervised_project_ids
    return Project.none unless supervisor?
    Project.where(student_id: student_ids).select(:id)
  end

  def student_ids
    return [] unless supervisor?
    students.pluck(:id)
  end

  def assign_supervisor_from_email!
    return if supervisor_email.blank? || !student?
    self.supervisor = User.find_by(email: supervisor_email.strip.downcase, role: :supervisor)
  end

  private

  def student_must_have_supervisor
    return unless student?
    return if supervisor_id.present?
    errors.add(:supervisor_email, "can't be blank for students") if supervisor_email.blank?
  end

  def supervisor_email_must_exist
    return unless student? && supervisor_email.present?
    sup = User.find_by(email: supervisor_email.strip.downcase, role: :supervisor)
    errors.add(:supervisor_email, "no supervisor found with this email") unless sup
  end
end
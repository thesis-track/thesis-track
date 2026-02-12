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
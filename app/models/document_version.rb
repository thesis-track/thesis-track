# frozen_string_literal: true

class DocumentVersion < ApplicationRecord
  belongs_to :document
  has_one_attached :file
  has_many :feedbacks, dependent: :nullify

  validates :version_number, presence: true, uniqueness: { scope: :document_id }
  validate :file_must_be_attached

  before_validation :set_version_number, on: :create

  def version_label
    "v#{version_number}"
  end

  private

  def file_must_be_attached
    errors.add(:file, "must be present") unless file.attached?
  end

  def set_version_number
    return if version_number.present?
    self.version_number = (document.document_versions.maximum(:version_number) || 0) + 1
  end
end
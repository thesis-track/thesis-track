# frozen_string_literal: true

class Document < ApplicationRecord
  belongs_to :project
  has_many :document_versions, dependent: :destroy
  has_many :feedbacks, through: :document_versions

  validates :title, presence: true
end

# frozen_string_literal: true

class Meeting < ApplicationRecord
  belongs_to :project

  validates :title, presence: true
  validates :scheduled_at, presence: true

  scope :upcoming, -> { where("scheduled_at >= ?", Time.current).order(:scheduled_at) }
  scope :past, -> { where("scheduled_at < ?", Time.current).order(scheduled_at: :desc) }
end

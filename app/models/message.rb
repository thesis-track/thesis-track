# frozen_string_literal: true

class Message < ApplicationRecord
  belongs_to :project
  belongs_to :sender, class_name: "User"
  belongs_to :receiver, class_name: "User"

  validates :body, presence: true

  scope :ordered, -> { order(created_at: :asc) }
  scope :search_body, ->(query) { where("body ILIKE ?", "%#{sanitize_sql_like(query)}%") }
end

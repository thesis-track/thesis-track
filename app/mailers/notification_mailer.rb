# frozen_string_literal: true

# Optional email summary for notifications (stub – not invoked by default).
# Enable by calling NotificationMailer.digest(user).deliver_later from a job if desired.
class NotificationMailer < ApplicationMailer
  # Stub: sends a digest of unread notifications to the user.
  # Design only; call from a scheduled job if you want daily/weekly email summaries.
  def digest(user)
    @user = user
    @notifications = user.notifications.unread.recent_first.limit(20)
    mail(
      to: user.email,
      subject: "ThesisTrack – Notification summary"
    )
  end
end

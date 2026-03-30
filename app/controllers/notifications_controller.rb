# frozen_string_literal: true

class NotificationsController < ApplicationController
  def index
    # Backfill notifications for unread messages that never got one (e.g. sent before the feature existed)
    current_user.ensure_notifications_for_unread_messages!
    @notifications = current_user.notifications.recent_first.limit(50)
  end

  def mark_read
    @notification = current_user.notifications.find(params[:id])
    @notification.mark_read!
    redirect_back fallback_location: notifications_path, notice: "Marked as read."
  end

  def mark_all_read
    current_user.notifications.unread.update_all(read_at: Time.current)
    redirect_back fallback_location: notifications_path, notice: "All marked as read."
  end
end

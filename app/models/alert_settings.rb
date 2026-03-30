# frozen_string_literal: true

# Global alert thresholds. Read from ENV with defaults.
# Example ENV: STALE_DAYS=5 NO_REPLY_DAYS=3 DEADLINE_ALERT_DAYS=5,1
class AlertSettings
  # Days without reply before thread is "stale"
  def self.stale_threshold_days
    (ENV["STALE_DAYS"] || "5").to_i
  end

  # Days before sending "no reply" reminder to the person who should reply (default 5)
  def self.no_reply_reminder_days
    (ENV["NO_REPLY_DAYS"] || "5").to_i
  end

  # No activity for this many days → flag project yellow
  def self.no_activity_yellow_days
    (ENV["NO_ACTIVITY_YELLOW_DAYS"] || "10").to_i
  end

  # No activity for this many days → flag project red
  def self.no_activity_red_days
    (ENV["NO_ACTIVITY_RED_DAYS"] || "14").to_i
  end

  # Days before deadline to send reminder (e.g. [5, 1] = 5 days and 1 day before)
  def self.deadline_alert_days
    (ENV["DEADLINE_ALERT_DAYS"] || "5,1").to_s.split(",").map(&:to_i).sort.reverse
  end

  # Days of no reply to consider "medium" risk
  def self.no_reply_medium_risk_days
    7
  end

  # Days of no activity to consider "high" risk
  def self.no_activity_high_risk_days
    14
  end
end

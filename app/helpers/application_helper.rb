module ApplicationHelper
  THREAD_STATUS_LABELS = {
    awaiting_supervisor_reply: "Awaiting your reply",
    awaiting_student_reply: "Awaiting student reply",
    responded: "Active",
    stale: "Stale"
  }.freeze

  def body_page_class
    return "auth-page" if auth_page?
    return "landing-page" if controller_name == "pages" && action_name == "home"
    ""
  end

  def auth_page?
    controller_path.include?("devise") || controller_name == "registrations"
  end

  def thread_status_badge(project)
    status = project.thread_status
    label = THREAD_STATUS_LABELS[status] || status.to_s.humanize
    css = case status
          when :stale then "badge badge-stale"
          when :awaiting_supervisor_reply then "badge badge-warning"
          when :awaiting_student_reply then "badge badge-info"
          else "badge badge-neutral"
          end
    tag.span(label, class: css)
  end
end

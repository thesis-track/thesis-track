module ApplicationHelper
  def body_page_class
    return "auth-page" if auth_page?
    return "landing-page" if controller_name == "pages" && action_name == "home"
    ""
  end

  def auth_page?
    controller_path.include?("devise") || controller_name == "registrations"
  end
end

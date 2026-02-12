# frozen_string_literal: true

module Authenticatable
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :logged_in?
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    return if logged_in?
    redirect_to login_path, alert: "Please log in to continue."
  end
end

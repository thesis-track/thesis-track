# frozen_string_literal: true

class RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: sign_up_keys)
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: account_update_keys)
  end

  def sign_up_keys
    %i[first_name last_name role supervisor_email student_id degree_programme department staff_id]
  end

  def account_update_keys
    %i[first_name last_name student_id degree_programme department staff_id]
  end
end
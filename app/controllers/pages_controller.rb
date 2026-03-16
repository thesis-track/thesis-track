# frozen_string_literal: true

class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]

  def home
    if user_signed_in?
      redirect_to dashboard_path
    else
      render :home
    end
  end

  def how_to_use
    render :how_to_use
  end
end

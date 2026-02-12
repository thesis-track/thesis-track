# frozen_string_literal: true

# Ensure Devise route helpers are loaded (fixes load-order issues)
require "devise"

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  devise_for :users, controllers: { registrations: "registrations" }

  root "pages#home", as: :root
  get "dashboard", to: "dashboard#show", as: :dashboard
  get "get_started", to: "onboarding#show", as: :get_started
  post "get_started", to: "onboarding#create"

  resources :projects do
    resources :tasks
    resources :meetings
    resources :messages, only: %i[index create]
    resources :documents, only: %i[index show new create] do
      resources :document_versions, only: %i[show create destroy], path: "versions"
    end
    resources :feedbacks
  end
end
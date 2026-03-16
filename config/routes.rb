# frozen_string_literal: true

# Ensure Devise route helpers are loaded (fixes load-order issues)
require "devise"

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  devise_for :users, controllers: { registrations: "registrations" }

  root "pages#home", as: :root
  get "how_to_use", to: "pages#how_to_use", as: :how_to_use
  get "dashboard", to: "dashboard#show", as: :dashboard
  patch "dashboard/meeting_link", to: "dashboard#update_meeting_link", as: :dashboard_meeting_link
  get "messages", to: "conversations#index", as: :messages
  get "get_started", to: "onboarding#show", as: :get_started
  post "get_started", to: "onboarding#create"

  resources :notifications, only: %i[index] do
    collection { post :mark_all_read }
    member { patch :mark_read }
  end

  resources :projects do
    member do
      post :complete_phase
      get :feed
    end
    resources :weekly_progress_updates, only: %i[index new create update], path: "progress"
    resources :tasks do
      resource :task_submission, only: %i[create update] do
        post :approve, action: :approve
      end
    end
    resources :meetings
    resources :messages, only: %i[index create] do
      member { patch :acknowledge }
    end
    resources :documents, only: %i[index show new create] do
      resources :document_versions, only: %i[show create destroy], path: "versions"
    end
    resources :feedbacks do
      member { patch :acknowledge }
    end
  end
end
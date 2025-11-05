# config/routes.rb
Rails.application.routes.draw do
  namespace :admin do
    resources :invitations, only: [ :index, :new, :create, :destroy ]
    resources :users, only: [ :index ] do
      member do
        post :promote_to_teacher
        post :demote_to_student
      end
    end
  end

  get "home/index"
  devise_for :users, controllers: {
    registrations: "users/registrations"
  }

  get "up" => "rails/health#show", as: :rails_health_check
  root "home#index"
  resources :invitations, only: [ :show ]

  resources :classrooms do
    collection do
      post :join
    end

    member do
      delete :remove_student
    end

    resources :quizzes do
      member do
        post :start
        post :submit
        get :solve
        get :results
        patch :activate
        patch :deactivate
      end

      resources :questions

      resource :ai_questions, only: [ :new, :create ] do
        collection do
          get :generating_status
          post :add_to_quiz
          post :add_all_to_quiz
          delete :clear_questions
        end
      end
    end
  end

  resources :quiz_results, only: [] do
    member do
      get :show, as: :details
      patch :deactivate
      patch :allow_retake
    end
  end


  get "/test_ai", to: "test_ai#test_generation"
end

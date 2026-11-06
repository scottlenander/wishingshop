Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  # Sign-up at /sign_up.
  get "sign_up", to: "registrations#new", as: :new_registration
  post "sign_up", to: "registrations#create", as: :registration
  # After logging in to a closed account: keep or change the email, then reactivate.
  resource :reactivation, only: %i[ show create ]
  # My account: details, password, close.
  resource :account, only: %i[ show edit update destroy ]
  resource :account_password, only: %i[ edit update ], path: "account/password"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  # Playwright test-data shortcuts (E2e::DataController). Never drawn in
  # production; elsewhere they return 404 unless bin/e2e-server sets E2E=1.
  unless Rails.env.production?
    namespace :e2e do
      post "users/reset", to: "data#reset_user"
      post "users/active", to: "data#set_user_active"
      post "products/stock", to: "data#set_stock"
      post "announcements/delete", to: "data#delete_announcements"
      post "featured_products/delete", to: "data#delete_featured_products"
    end
  end

  # App routes
  root "products#index"
  resources :products do
    resources :subscribers, only: [ :create ]
    resources :reviews, only: %i[ index new create edit update destroy ]
  end
  resource :cart, only: :show
  resources :cart_items, only: %i[ create update destroy ]
  resource :checkout, only: %i[ show create ]
  resources :addresses, except: :show
  resources :orders, only: %i[ index show ], param: :number
  resources :subscriptions, only: [ :index, :destroy ]
  resource :unsubscribe, only: [ :show ]

  namespace :admin do
    resources :users, except: :show do
      patch :restore, on: :member
    end
    resources :subscribers, except: :show
    resources :orders, only: [ :index ]
    resources :announcements, except: :show
    resources :featured_products, except: :show
    resource :product_import, only: %i[ new create ] do
      get :template   # blank CSV with the column headers
      get :export     # current products as CSV, to edit and upload again
      post :apply
    end
  end

  # View sent emails in development
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
end

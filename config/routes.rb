Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  resources :interests, only: [ :index ]
  resources :political_entities, only: [ :show, :index ], path: "political-entities" do
    get :export, on: :member
  end
  resources :about, only: [ :show ]
  resources :comparison, only: [ :index ]


  # Defines the root path route ("/")
  root "home#show"
end

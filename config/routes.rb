Rails.application.routes.draw do
  get "up" => "rails/health#show", :as => :rails_health_check

  post "search", to: "search#create", as: :search

  root "articles#index"
end

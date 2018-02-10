Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  resources :coins do
    collection do
      get 'watchlist'
    end
  end
  root 'coins#index'
end

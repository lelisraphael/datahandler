Rails.application.routes.draw do
  get 'home/index'
  mount_devise_token_auth_for 'User', at: 'auth'
  namespace :api do
    namespace :v1 do
      resources :indeed
    end
  end
end

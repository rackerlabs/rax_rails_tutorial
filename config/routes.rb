Serverly::Application.routes.draw do
  resources :servers
  resources :images
  root :to => 'servers#index'
end

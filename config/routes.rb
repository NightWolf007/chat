Rails.application.routes.draw do

  namespace :api, as: nil, defaults: {format: 'json'} do
    namespace :v1, as: nil do
      devise_for :users, controllers:
        {
          :passwords => 'api/devise/passwords',
          :registrations => 'api/devise/registrations',
          :sessions => 'api/devise/sessions'
        }

      get '/users/me' => 'users#me'
      resources :users, :only => [:show, :update, :destroy]

      get '/private/:id' => 'private_rooms#show'
      post '/private' => 'private_rooms#create'
      get '/anonymous/:id' => 'anonymous_rooms#show'
      post '/anonymous' => 'anonymous_rooms#create'
      get '/messages' => 'channels#messages'
      post '/rooms/:id/upload' => 'channels#upload'
    end
  end
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end

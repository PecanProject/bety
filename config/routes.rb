BetyRails3::Application.routes.draw do # RAILS3 |map| removed
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
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

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'


  resources :yieldsviews, :only => [:show]
  resources :workflows
  resources :formats_variables
  resources :dbfiles do
    collection do
      get :no
    end
    member do
      get :download
      get :unlink
    end
  end

  resources :machines
  resources :methods
  resources :ensembles
  resources :raws do
    collection do
      get :download
    end
  end

  resources :entities
  resources :formats
  resources :likelihoods
  resources :inputs
  resources :models
  resources :runs
  resources :posteriors
  resources :covariates
  resources :pfts do
    member do
      get :make_clone
    end
  end

  resources :managements
  resources :treatments do
    collection do
      get :linked
      get :new_management
    end
  end

  resources :sites do
    collection do
      get :map
    end
  end

  resources :citations
  resources :variables
  resources :species
  resources :cultivars
  resources :priors do
    member do
      get 'preview'
    end
  end

  resources :yields
  resources :traits do
    collection do
      get :linked
    end
  end

  resources :citations_sites, :only => [:index, :new, :create]
  resources :citations_treatments, :only => [:index, :new, :create]
  resources :managements_treatments, :only => [:index, :new, :create]
  resources :pfts_priors, :only => [:index, :new, :create]
  resources :pfts_species, :only => [:index, :new, :create]
  resources :sessions, :only => [:new, :create, :destroy], :controller => 'sessions'


  resources :errors, :only => [:index, :create]
  resources :users

  match '/maps' => 'maps#location_yields'

  match '/ebi_forwarded' => 'sessions#ebi_forwarded', :as => :ebi_forwarded


  root :to => "sessions#new"

  match '/:controller(/:action(/:id))'
  match ':controller/:action.:format' => '#index'



  match '/logout' => 'sessions#destroy', :as => :logout
  match '/login' => 'sessions#new', :as => :login
  match '/register' => 'users#create', :as => :register
  match '/signup' => 'users#new', :as => :signup

  #route for 'static' content
  # RAILS3 commented out below and added next in order to get help bubble docs working
  # match '*path' => 'static#index'
  match ':action' => 'static#:action'
end

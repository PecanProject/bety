ActionController::Routing::Routes.draw do |map|
  map.resources :machines

  map.resources :methods

  map.resources :ensembles

  map.resources :raws,
                :collection => { :download => :get }

  map.resources :entities

  map.resources :formats

  map.resources :likelihoods

  map.resources :inputs

  map.resources :models

  map.resources :runs

  map.resources :posteriors

  map.resources :errors, :only => [:index, :create]

  map.logout '/logout', :controller => 'sessions', :action => 'destroy'
  map.login '/login', :controller => 'sessions', :action => 'new'
  map.register '/register', :controller => 'users', :action => 'create'
  map.signup '/signup', :controller => 'users', :action => 'new'
  map.resources :users

  map.resource :session

  map.resources :covariates

  map.resources :pfts

  map.resources :managements

  map.resources :treatments, :collection => { 
                               :linked => :get,
                               :new_management => :get} 

  map.resources :sites, :collection => {
                          :map => :get }

  map.resources :citations

  map.resources :variables

  map.resources :species

  map.resources :cultivars

  map.resources :priors

  map.resources :yields

  map.resources :traits, :collection => {
                           :nice => :get,
                           :new_multi => :get,
                           :create_multi => :post,
                           :linked => :get }


  map.resources :citations_sites, :controller => 'citations_sites', :only => [:index, :new, :create]
  map.resources :citations_treatments, :controller => 'citations_treatments', :only => [:index, :new, :create]
  map.resources :managements_treatments, :controller => 'managements_treatments', :only => [:index, :new, :create]
  map.resources :pfts_priors, :controller => 'pfts_priors', :only => [:index, :new, :create]
  map.resources :pfts_species, :controller => 'pfts_species', :only => [:index, :new, :create]

  map.resources :input_files, :controller => 'input_files', :only => [:download], :collection => { :download => :get }

  map.connect 'search.:format', :controller => 'search', :action => :index

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action.:format'


  #route for 'static' content
  map.connect '/maps/mapoverlay/*path', :controller => 'maps', :action => 'mapoverlay'
  map.connect '*path', :controller => 'static'

end

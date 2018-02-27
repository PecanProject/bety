Rails.application.routes.draw do
  apipie
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

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'

  # route for autocompletion actions used by the bulk upload wizard:
  get ':controller/bu_autocomplete', action: 'bu_autocomplete'

  # route for other autocompletion actions:
  get ':controller/autocomplete', action: 'autocomplete'

  resources :yieldsviews, :only => [:show]
  resources :workflows
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

  resources :entities
  post '/feedback/feedback_email' => 'feedback#feedback_email'
  resources :formats do
    post :add_formats_variables, on: :collection
  end
  get 'formats/edit_formats_variables'
  get '/formats/rem_formats_variables(/:id)' => 'formats#rem_formats_variables'

  resources :likelihoods
  resources :inputs do
    collection do
      get :edit_inputs_variables # for linking and unlinking variables
      post :edit_inputs_variables # for searching variables
      get :edit_inputs_files # for linking and unlinking files
      post :edit_inputs_files # for searching files
    end
  end
  resources :models do
    member do
      get :edit_models_files
      post :edit_models_files
    end
  end
  resources :modeltypes do
    # Because of the way the controller was written to deal with the associates
    # set of formats, we have to use collection here even though the actions
    # pertain to a particular modeltype:
    collection do
      post :add_modeltypes_format
      post :edit_modeltypes_format
      get :remove_modeltypes_format
    end
    # TO DO: do the routing of association editing properly.
  end
  resources :runs
  resources :posteriors
  resources :covariates
  resources :pfts do
    member do
      get :search_priors
      get :make_clone
      get :edit2_pfts_species # for adding a species to the pft
      post :edit2_pfts_species # for species search
    end
    collection do
      get :add_pfts_priors
      get :rem_pfts_priors
   end
  end

  resources :managements do
    member do
      get :search_treatments
    end
    collection do
      get :add_managements_treatments
      get :rem_managements_treatments
    end
  end
  resources :treatments do
    collection do
      get :linked
      get :new_management
      get :flag_control
      post :edit_managements_treatments
      get :rem_managements_treatments
      post :create_new_management
    end
  end

  resources :sitegroups do
    member do
      get :edit_sitegroups_sites
      post :edit_sitegroups_sites
    end
  end

  resources :sites do
    member do
      get :search_citations
    end
    collection do
      get :map
      get :linked
      get :rem_citations_sites
      get :add_citations_sites
    end
  end

  resources :citations do
    member do
      get :search_sites
    end
    collection do
      get :rem_citations_sites
      get :add_citations_sites
    end
  end
  resources :variables
  resources :species do
    member do
      get :search_pfts
    end
    collection do
      get :rem_pfts_species
      get :add_pfts_species # for adding a pft relationship
      post :species_search # for help making new yields
    end
  end
  resources :cultivars
  resources :priors do
    member do
      get :preview
      get :search_pfts
    end
    collection do
      get :rem_pfts_priors
      get :add_pfts_priors
    end
  end

  resources :yields do
    collection do
      post :access_level
      post :checked
    end
  end
  resources :traits do
    member do
      get :unlink_covariate
    end
    collection do
      get :linked
      post :access_level
      post :checked
      post :trait_search
    end
  end

  resources :citations_sites, :only => [:index, :new, :create]
  resources :citations_treatments, :only => [:index, :new, :create]
  resources :managements_treatments, :only => [:index, :new, :create]
  resources :pfts_priors, :only => [:index, :new, :create]
  resources :pfts_species, :only => [:index, :new, :create]
  resources :sessions, :only => [:new, :create, :destroy], :controller => 'sessions'


  resources :users do
    collection do
      get :create_apikey
    end
  end
  resources :schemas, :only => [:index]
  resources :search, :only => :index
  resources :trait_covariate_associations, only: :index

  resources :experiments

  # API
  namespace :api, defaults: { format: 'json' } do
    namespace :v1 do
      [:citations, :covariates, :cultivars, :dbfiles, :ensembles, :entities,
       :experiments, :formats, :inputs, :likelihoods, :machines,
       :managements, :methods, :mimetypes, :models, :modeltypes, :pfts,
       :posteriors, :priors, :runs, :sites, :species, :traits,
       :treatments, :users, :variables, :yields
      ].each do |model|
        resources model, only: [:index, :show]
      end
      resources :search, only: :index
      resources :traits, only: :create
    end
  end

  # deprecated "beta" path (same as v1)
  namespace :api, defaults: { format: 'json' } do
    namespace :v1, path: :beta do
      [:citations, :covariates, :cultivars, :dbfiles, :ensembles, :entities,
       :experiments, :formats, :inputs, :likelihoods, :machines,
       :managements, :methods, :mimetypes, :models, :modeltypes, :pfts,
       :posteriors, :priors, :runs, :sites, :species, :traits,
       :treatments, :users, :variables, :yields
      ].each do |model|
        resources model, only: [:index, :show]
      end
      resources :search, only: :index
      resources :traits, only: :create
    end
  end

  match '/api', controller: 'api/base', action: 'bad_url', via: [:get, :post]
  match '/api/*remainder', controller: 'api/base', action: 'bad_url', via: [:get, :post]

  get '/application/use_citation/:id', controller: 'application', action: 'use_citation'
  get '/application/remove_citation'

  get '/maps' => 'maps#location_yields'

  get '/ebi_forwarded' => 'sessions#ebi_forwarded', :as => :ebi_forwarded


  root :to => "sessions#new"

  get '/logout' => 'sessions#destroy', :as => :logout
  get '/login' => 'sessions#new', :as => :login
  post '/register' => 'users#create', :as => :register
  get '/signup' => 'users#new', :as => :signup

  #route for 'static' content
  # RAILS3 commented out below and added next in order to get help bubble docs working
  # match '*path' => 'static#index'
  get ':action' => 'static#:action'

  # add named routes for bulk_upload controller:
  get '/bulk_upload/start_upload' => 'bulk_upload#start_upload', :as => :start_upload
  match '/bulk_upload/display_csv_file', :as => :show_upload_file_contents, via: [:get, :post]
  get '/bulk_upload/choose_global_citation', as: :choose_global_citation
  get '/bulk_upload/choose_global_data_values', :as => :choose_global_data_values
  match '/bulk_upload/confirm_data', :as => :bulk_upload_data_confirmation, via: [:get, :post]
  post '/bulk_upload/insert_data', :as => :bulk_upload_data_insertion

  # This seems a somewhat kludgy way to get 'link_to "CF Guidelines",
  # guidelines_path' to create a robust link (i.e., one that works even in
  # subdirectory deployments) to /public/guidelines.html, but it works.
  get '/guidelines.html' => redirect('/guidelines.html'), :as => :guidelines

end

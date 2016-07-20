module AuthenticatedSystem
  protected
    # Returns the numeric level of access for each user id
    # or 100 as each level will contain at least the rights
    # of the level below it.
    #def access_level(user_id)
    #  #Access levels
    #  admin = [1,2,3,4,5,6]
    #  data_managers = []
    #  ebi_collaborators = []
    #  external_scientists = [7]
      

    #  if admin.include?(user_id)
    #    return 1
    #  elsif data_managers.include?(user_id)
    #    return 2
    #  elsif ebi_collaborators.include?(user_id)
    #    return 3
    #  elsif external_scientists.include?(user_id)
    #    return 4
    #  else
    #    return 100
    #  end
    #end

    # Returns true or false if the user is logged in.
    # Preloads @current_user with the user model if they're logged in.
    def logged_in?
      !!current_user
    end

    # Accesses the current user from the session.
    # Future calls avoid the database because nil is not equal to false.
    def current_user
      @current_user ||= (login_from_session || login_from_basic_auth || login_from_cookie || login_from_api_key || login_from_config) unless @current_user == false
    end

    # Store the given user id in the session.
    def current_user=(new_user)
      session[:user_id] = new_user ? new_user.id : nil
      @current_user = new_user || false
    end

    def permissions(action_name,controller_class = nil)
      # RAILS3 changed below line with second below line. controller_class_name appears to have been removed Rails3
      # controller_class = controller_class_name if controller_class.nil?
      controller_class = "#{controller_name.camelize}Controller" if controller_class.nil?
      admin_requirement = ["UsersController.ALL" ]
      manage_requirement = ["CitationsController.ALL",
                                "CovariatesController.ALL",
                                "CultivarsController.ALL",
                                "DbfilesController.ALL",
                                "EnsemblesController.ALL",
                                "EntitiesController.ALL",
                                "ErrorsController.ALL",
                                "FormatsController.ALL",
                                "MachinesController.ALL",
                                "ManagementsController.ALL",
                                "MethodsController.ALL",
                                "PftsController.ALL",
                                "PriorsController.ALL",
                                "PftsPriorsController.ALL",
                                "PftsSeciesController.ALL",
                                "RawsController.ALL",
                                "SitesController.ALL",
                                "SpeciesController.ALL",
                                "TraitsController.ALL",
                                "TreatmentsController.ALL",
                                "VariablesController.ALL",
                                "VisitorsController.ALL",
                                "WorkflowsController.ALL",
                                "YieldsController.ALL",
                                "PosteriorsController.ALL",
                                "PosteriorsRunsController.ALL",
                                "RunsController.ALL",
                                "LikelihoodsController.ALL",
                                "ModelsController.ALL",
                                "ModeltypesController.ALL",
                                "InputsRunsController.ALL",
                                "YieldsviewsController.ALL",
                                "InputsVariablesController.ALL",
                                "InputsController.ALL" ]
      create_requirement = ["ApplicationsController.ALL",
                                "BulkUploadController.ALL",
                                "CitationsController.autocomplete",
                                "CitationsController.bu_autocomplete", # <-- needed for bulk upload
                                "CitationsController.new",
                                "CitationsController.create",
                                "CitationsController.edit",
                                "CitationsController.update",
                                "CitationsSitesController.create",
                                "CitationsSitesController.new",
                                "CitationsTreatmentsController.create",
                                "CitationsTreatmentsController.new",
                                "CovariatesController.new",
                                "CovariatesController.create",
                                "CovariatesController.edit",
                                "CovariatesController.update",
                                "CultivarsController.new",
                                "CultivarsController.create",
                                "CultivarsController.edit",
                                "CultivarsController.update",
                                "CultivarsController.bu_autocomplete", # <-- needed for bulk upload
                                "EnsemblesController.new",
                                "EnsemblesController.create",
                                "EnsemblesController.edit",
                                "EnsemblesController.update",
                                "EntitiesController.new",
                                "EntitiesController.create",
                                "EntitiesController.edit",
                                "EntitiesController.update",
                                "ErrorsController.index",
                                "ErrorsController.fixed",
                                "ErrorsController.show",
                                "FormatsController.new",
                                "FormatsController.create",
                                "FormatsController.edit",
                                "FormatsController.update",
                                "FormatsController.edit_formats_variables",
                                "FormatsController.rem_formats_variables",
                                "ManagementsController.new",
                                "ManagementsController.create",
                                "ManagementsController.edit",
                                "ManagementsController.update",
                                "ManagementsController.edit_managements_treatments",
                                "ManagementsController.rem_managements_treatments",
                                "ManagementsTreatmentsController.new",
                                "ManagementsTreatmentsController.create",
                                "MethodsController.new",
                                "MethodsController.create",
                                "MethodsController.edit",
                                "MethodsController.update",
                                "PriorsController.new",
                                "PriorsController.create",
                                "PriorsController.edit",
                                "PriorsController.update",
                                "PftsController.new",
                                "PftsController.create",
                                "RawsController.new",
                                "RawsController.create",
                                "RawsController.edit",
                                "RawsController.update",
                                "SitesController.new",
                                "SitesController.create",
                                "SitesController.edit",
                                "SitesController.update",
                                "SitesController.linked",
                                "SitesController.bu_autocomplete", # <-- needed for bulk upload
                                "SitesController.edit_citations_sites",
                                "SitesController.rem_citations_sites",
                                "SitegroupsController.new",
                                "SitegroupsController.create",
                                "SitegroupsController.edit",
                                "SitegroupsController.update",
                                "SpeciesController.new",
                                "SpeciesController.create",
                                "SpeciesController.edit",
                                "SpeciesController.update",
                                "SpeciesController.bu_autocomplete", # <-- needed for bulk upload
                                "SpeciesController.species_search",
                                "TreatmentsController.new",
                                "TreatmentsController.edit",
                                "TreatmentsController.update",
                                "TreatmentsController.create",
                                "TreatmentsController.linked",
                                "TreatmentsController.bu_autocomplete", # <-- needed for bulk upload
                                "TreatmentsController.create_new_management",
                                "TraitsController.new",
                                "TraitsController.create",
                                "TraitsController.edit",
                                "TraitsController.update",
                                "TraitsController.destroy",
                                "TraitsController.access_level",
                                "TraitsController.checked",
                                "TraitsController.add_row",
                                "TraitsController.create_multi",
                                "TraitsController.new_multi",
                                "VariablesController.new",
                                "VariablesController.autocomplete",
                                "VariablesController.create",
                                "VariablesController.edit",
                                "VariablesController.update",
                                "YieldsController.new",
                                "YieldsController.access_level",
                                "YieldsController.checked",
                                "YieldsController.edit",
                                "YieldsController.update",
                                "YieldsController.destroy",
                                "YieldsController.create"]
      view_requirement = ["CitationsController.index",
                                "CitationsController.show",
                                "CitationsController.search",
                                "CitationsController.search_by_species",
                                "CitationsSitesController.index",
                                "CitationsTreatmentssController.index",
                                "CovariatesController.index",
                                "CovariatesController.show",
                                "CultivarsController.index",
                                "CultivarsController.show",
                                "EnsemblesController.index",
                                "EnsemblesController.search",
                                "EnsemblesController.show",
                                "EntitiesController.index",
                                "EntitiesController.show",
                                "ErrorsController.new",
                                "ErrorsController.create",
                                "FormatsController.index",
                                "FormatsController.show",
                                "ManagementsController.index",
                                "ManagementsController.show",
                                "ManagementsTreatmentsController.index",
                                "MapsController.ALL",
                                "PriorsController.index",
                                "PriorsController.show",
                                "PriorsController.preview",
                                "PriorsController.search",
                                "PftsController.index",
                                "PftsController.show",
                                "RawsController.index",
                                "RawsController.search",
                                "RawsController.show",
                                "SearchController.index",
                                "SitesController.index",
                                "SitesController.map",
                                "SitesController.show",
                                "SitegroupsController.index",
                                "SitegroupsController.show",
                                "SitegroupsController.search",
                                "SitegroupsController.edit_sitegroups_sites",
                                "SpeciesController.index",
                                "SpeciesController.show",
                                "SpeciesController.search",
                                "TreatmentsController.index",
                                "TreatmentsController.show",
                                "VariablesController.index",
                                "VariablesController.show",
                                "VariablesController.search",
                                "TraitsController.index",
                                "TraitsController.show",
                                "TraitsController.search",
                                "UsersController.index", 
                                "UsersController.show", 
                                "UsersController.edit", 
                                "UsersController.update", 
                                "YieldsController.index",
                                "YieldsController.search",
                                "YieldsController.show"]


      controller_action = controller_class + "." + action_name
      controller_all_actions = controller_class + ".ALL"

      if view_requirement.include?(controller_action) || view_requirement.include?(controller_all_actions)
        level = 4
      elsif create_requirement.include?(controller_action) || create_requirement.include?(controller_all_actions)
        level = 3
      elsif manage_requirement.include?(controller_action) || manage_requirement.include?(controller_all_actions)
        level = 2
      elsif admin_requirement.include?(controller_action) || admin_requirement.include?(controller_all_actions)
        level = 1
      else
        logger.info "Did not find level for " + controller_action
        level = 4
      end
      Rails.logger.debug("!!!!!!!!!!!! level = #{level}; controller_action = #{controller_action}")
      #level = 4 if level.nil?

      not_restricted_record = true
 
      if ['edit','update','show','destroy'].include?(action_name) and ['TraitsController','YieldsController'].include?(controller_class)
        not_restricted_record = false
        if controller_class == 'TraitsController'
          t = Trait.find(params[:id])
          not_restricted_record = true if t.user_id == self.current_user.id or self.current_user.access_level == 1 or (t.access_level >= self.current_user.access_level and t.checked)
        elsif controller_class == 'YieldsController'
          t = Yield.find(params[:id])
          not_restricted_record = true if t.user_id == self.current_user.id or self.current_user.access_level == 1 or (t.access_level >= self.current_user.access_level and t.checked)
        end
      end #if

      if 'location_yields' == action_name and 'MapsController' == controller_class
        not_restricted_record = false if self.current_user.access_level > 2
      end

      #if !session[:access_level].nil? and session[:access_level] <= level
      if self.current_user.page_access_level <= level and not_restricted_record
        return level
      else
        logger.info self.current_user.page_access_level.to_yaml
        logger.info level.to_yaml
        logger.info not_restricted_record.to_yaml
        return false
      end
    end



    # Check if the user is authorized
    #
    # Override this method in your controllers if you want to restrict access
    # to only a few actions or if you want to check if the user
    # has the correct rights.
    #
    # Example:
    #
    #  # only allow nonbobs
    #  def authorized?
    #    current_user.login != "bob"
    #  end
    #
    def authorized?(action = action_name, resource = nil)
      if logged_in? and permissions(action_name, resource)
        true
      else
        false
      end
    end

    # Filter method to enforce a login requirement.
    #
    # To require logins for all actions, use this in your controllers:
    #
    #   before_filter :login_required
    #
    # To require logins for specific actions, use this in your controllers:
    #
    #   before_filter :login_required, :only => [ :edit, :update ]
    #
    # To skip this in a subclassed controller:
    #
    #   skip_before_filter :login_required
    #
    def login_required
      authorized? || access_denied
    end

    # Redirect as appropriate when an access request fails.
    #
    # The default action is to redirect to the login screen.
    #
    # Override this method in your controllers if you want to have special
    # behavior in case the user is not authorized
    # to access the requested action.  For example, a popup window might
    # simply close itself.
    def access_denied
      respond_to do |format|
        format.html do
          store_location
          redirect_to new_session_path
        end
        # format.any doesn't work in rails version < http://dev.rubyonrails.org/changeset/8987
        # Add any other API formats here.  (Some browsers, notably IE6, send Accept: */* and trigger 
        # the 'format.any' block incorrectly. See http://bit.ly/ie6_borken or http://bit.ly/ie6_borken2
        # for a workaround.)
        format.any(:json, :xml) do
          request_http_basic_authentication 'Web Password'
        end
      end
    end

    # Store the URI of the current request in the session.
    #
    # We can return to this location by calling #redirect_back_or_default.
    def store_location
      # RAILS 3 request_uri is deprecated, use fullpath instead
      session[:return_to] = request.fullpath
    end

    # Redirect to the URI stored by the most recent store_location call or
    # to the passed default.  Set an appropriately modified
    #   after_filter :store_location, :only => [:index, :new, :show, :edit]
    # for any controller you want to be bounce-backable.
    def redirect_back_or_default(default)
      redirect_to(session[:return_to] || default)
      session[:return_to] = nil
    end

    # Inclusion hook to make #current_user and #logged_in?
    # available as ActionView helper methods.
    def self.included(base)
      base.send :helper_method, :current_user, :logged_in?, :authorized? if base.respond_to? :helper_method
    end

    #
    # Login
    #

    # Called from #current_user.  First attempt to login by the user id stored in the session.
    def login_from_session
      self.current_user = User.find(session[:user_id]) if session[:user_id]
    end

    # Called from #current_user.  Now, attempt to login by basic authentication information.
    def login_from_basic_auth
      authenticate_with_http_basic do |login, password|
        self.current_user = User.authenticate(login, password)
      end
    end

    def login_from_api_key
      unless params[:key].nil?
        u = User.find_by_apikey(params[:key])
      end
      u ? u : nil
    end
    
    #
    # Logout
    #

    # Called from #current_user.  Finaly, attempt to login by an expiring token in the cookie.
    # for the paranoid: we _should_ be storing user_token = hash(cookie_token, request IP)
    def login_from_cookie
      user = cookies[:auth_token] && User.find_by_remember_token(cookies[:auth_token])
      if user && user.remember_token?
        self.current_user = user
        handle_remember_cookie! false # freshen cookie token (keeping date)
        self.current_user
      end
    end

    # Called from #current_user. Try to attempt to login using the id provided in the config
    # of the application.
    def login_from_config
        self.current_user = User.find(BETY_USER) if defined? BETY_USER
    end

    # This is ususally what you want; resetting the session willy-nilly wreaks
    # havoc with forgery protection, and is only strictly necessary on login.
    # However, **all session state variables should be unset here**.
    def logout_keeping_session!
      # Kill server-side auth cookie
      @current_user.forget_me if @current_user.is_a? User
      @current_user = false     # not logged in, and don't do it for me
      kill_remember_cookie!     # Kill client-side auth cookie
      session[:user_id] = nil   # keeps the session but kill our variable
      # explicitly kill any other session variables you set
    end

    # The session should only be reset at the tail end of a form POST --
    # otherwise the request forgery protection fails. It's only really necessary
    # when you cross quarantine (logged-out to logged-in).
    def logout_killing_session!
      logout_keeping_session!
      reset_session
    end
    
    #
    # Remember_me Tokens
    #
    # Cookies shouldn't be allowed to persist past their freshness date,
    # and they should be changed at each login

    # Cookies shouldn't be allowed to persist past their freshness date,
    # and they should be changed at each login

    def valid_remember_cookie?
      return nil unless @current_user
      (@current_user.remember_token?) && 
        (cookies[:auth_token] == @current_user.remember_token)
    end
    
    # Refresh the cookie auth token if it exists, create it otherwise
    def handle_remember_cookie!(new_cookie_flag)
      return unless @current_user
      case
      when valid_remember_cookie? then @current_user.refresh_token # keeping same expiry date
      when new_cookie_flag        then @current_user.remember_me 
      else                             @current_user.forget_me
      end
      send_remember_cookie!
    end
  
    def kill_remember_cookie!
      cookies.delete :auth_token
    end
    
    def send_remember_cookie!
      cookies[:auth_token] = {
        :value   => @current_user.remember_token,
        :expires => @current_user.remember_token_expires_at }
    end

end

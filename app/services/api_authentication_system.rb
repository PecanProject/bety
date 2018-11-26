module ApiAuthenticationSystem
  include AuthenticatedSystem

  # Override default access_denied action.
  def access_denied
    if @errors
      @errors = "authentication failed: " + @errors
    else
      @errors = "authentication failed"
    end
    render status: 401
  end

  # Override default permissions method.
  def permissions(action_name, resource)
    # To access any action other than "index" or "show", the current user must
    # have at least "Creator" page access level (i.e., level 1, 2, or 3).  The
    # "index" and "show" actions are open to any registered user.
    if action_name == 'index' || action_name == 'show' || current_user.page_access_level <= 3
      true
    else
      false
    end
  end

  # Override "login_from_api_key" so that if no key is given or the given key is
  # invalid, the user is logged in as the guest user.
  def login_from_api_key
    key = params[:key]
    if key.nil?
      u = User.find_by_login('guestuser')
    else
      u = User.find_by_apikey(params[:key]) || User.find_by_login('guestuser')
    end

    if u.nil?
      @errors = "You must either use a valid API key or set up the guest user account."
    end

    return u
  end

end

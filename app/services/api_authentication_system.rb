# coding: utf-8
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
      u = User.find_by_login('guestuserx')
      if u.nil?
        @errors = "For key-less access to the API, you must set up the guest user account."
      end
    else
      u = User.find_by_apikey(params[:key])
      if u.nil?
        @errors = "Invalid API key.  To access the API as a guest user, omit the “key” parameter."
      end
    end

    return u
  end

end

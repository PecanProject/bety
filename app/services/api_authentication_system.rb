module ApiAuthenticationSystem
  include AuthenticatedSystem

  # Override default access_denied action.
  def access_denied
    @errors = "authenication failed"
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

end

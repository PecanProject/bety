module ApiAuthenticationSystem
  include AuthenticatedSystem

  # Override default access_denied action.
  def access_denied
    @errors = "authenication failed"
    render status: 401
  end

  # Override default permissions method.
  # For now, allow all users access to all api actions.
  def permissions(action_name, resource)
    true
  end

end

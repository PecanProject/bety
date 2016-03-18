module ApiAuthenticationSystem
  include AuthenticatedSystem

  # Override default access_denied action.
  def access_denied
    @error = "authenication failed"
    render
  end

  # Override default permissions method.
  # For now, allow all users access to all api actions.
  def permissions(action_name, resource)
    true
  end

end

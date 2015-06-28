class StatnameCallbacks
  def before_validation(model)
    model.statname ||= ''
  end
end

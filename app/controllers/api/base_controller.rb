class Api::BaseController < ApplicationController

  # Not sure why or even if these eight lines are needed.  Just copied them from
  # article at https://labs.kollegorna.se/blog/2015/04/build-an-api-now/
  # Presumably we'll change things around here when we decide what sort of
  # authentication and authorization we want to do.
  protect_from_forgery with: :null_session

  #  before_action :destroy_session <-- Rails 4
  before_filter :destroy_session

  def destroy_session
    request.session_options[:skip] = true
  end



  private

  # utility method shared by all the API controllers

  # Given a model class and a params hash, construct a WHERE clause by taking
  # the conjunction of clauses of the form "key = value" where "key" is an
  # attribute of "model"; use this as the basis of a query and return the
  # result, subject to the values specified by the limit and offset parameters,
  # if given.
  def query(model, params)
    where_params = params.slice(*model.column_names)

    limit = nil
    if params.has_key? "limit"
      limit = params['limit']
    end

    offset = nil
    if params.has_key? "offset"
      offset = params['offset']
    end


    result = model.where(where_params)

    # If limit and/or offset parameters were given, use them.
    if offset.nil?
      result = result.limit(limit).offset(offset)
    end
    if !limit.nil?
      result = result.limit(limit)
    end

    result
  end

end

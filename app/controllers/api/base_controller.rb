class Api::BaseController < ActionController::Base

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



  # This ensures that when we are in the API realm, an exception won't get
  # handled by the default Rails exception handler that returns an HTML result.
  rescue_from StandardError do |e|
    logger.info("UNEXPECTED EXCEPTION: #{e.class}\n#{e}")
    # only show the first line of the backtrace in production mode:
    logger.info("THROWN AT: #{e.backtrace[0]}")
    # show the rest in development mode:
    logger.debug("BACKTRACE: #{e.backtrace.join("\n")}")
    @errors = "UNEXPECTED EXCEPTION #{e.class}. #{e.message}"
    render status: 400
  end

  # Actions

  # We route all illegitimate requests beginning "/api" here so that we
  # return errors in JSON rather than the default HTML:
  def bad_url
    @errors = "There is no resource at this URL.  Visit #{root_url}apipie for information about available API paths."
    render status: 404
  end

  private

  # Utility method shared by all the API controllers

  # Given a model class and a params hash, construct a WHERE clause by taking
  # the conjunction of clauses of the form "key = value" where "key" is an
  # attribute of "model"; use this as the basis of a query and return the
  # result, subject to the values specified by the limit and offset parameters,
  # if given.  If a param value is a string beginning with a tilde (~), the
  # clause "key = value" is replaced by "key::text ~ value*", where "value*" is
  # "value" with the tilde removed.
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

    # restrict traits and yields by access level
    if model == Trait || model == Yield
      model = model.all_limited(current_user)
    end

	if model == User
	  if current_user.page_access_level > 1
        model = model.where("id = #{current_user.id}")
      end
    end

    # Do filtering by regexp matching first.  Note that fuzzy_match_restrictions
    # may modify where_params by removing key-value pairs corresponding to fuzzy
    # matches.
    model = fuzzy_match_restrictions(model, where_params)

    # Now filter by exact matching.
    result = model.where(where_params)

    # "limit(nil)" means no limit, so use nil if limit is "all" or "none"
    if limit == "all" || limit == "none"
      limit = nil
    end

    # If limit and/or offset parameters were given, use them.
    if !offset.nil?
      result = result.limit(limit).offset(offset)
    end
    if !limit.nil?
      result = result.limit(limit)
    end

    result
  end



  # Utility method used by the 'query' method

  # Removes all key-value pairs from where_params for which the value
  # is a string beginning with '~' and then filters the table or query
  # results corresponding to model_or_relation by doing a case
  # insensitive regular expression match of column values
  # corresponding to keys in where_params (converted to text, if
  # necessary) with the corresponding values (with the leading tilde
  # removed).  The result set (an ActiveRecord::Relation)--or
  # model_or_relation itself if there were not fuzzy parameters--is
  # then returned.  The where_params is modified in place, and the
  # modified version is then available to the caller.
  def fuzzy_match_restrictions(model_or_relation, where_params)
    fuzzy_params = where_params.select { |k, v| v.is_a?(String) && v[0] == '~' }

    # If there are not fuzzy-match parameters, just return the model_or_relation
    # as is:
    if fuzzy_params.empty?
      return model_or_relation
    end

    # remove these from where_params
    where_params.delete_if { |k, v| fuzzy_params.has_key?(k) }

    kv_pairs = fuzzy_params.to_a
    
    where_clause_array = kv_pairs.map { |kv| "#{kv[0]}::text ~* ?" }
    where_clause = where_clause_array.join(" AND ")
    value_array = kv_pairs.map { |kv| kv[1][1..-1] }

    model_or_relation = model_or_relation.where(where_clause, *value_array)

  end    
    

end

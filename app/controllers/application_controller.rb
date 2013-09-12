# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base

  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem
  require 'csv'
  
  if Rails.env == "production"
    require "#{Rails.root}/lib/mercator" 
    include Mercator
  end

  rescue_from ActiveRecord::RecordNotFound, :with => :not_found

  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  $sort_table = {false => " asc", true =>" desc"}

  def use_citation
    session['citation'] = params[:id]
    redirect_to :controller => "sites"
  end
  
  def remove_citation
    session['citation'] = nil
    redirect_to :controller => "citations"
  end

  def not_found
    render :file => Rails.root.to_s + '/app/views/static/404.html', :layout => true, :status => 404
  end
 
  def sort_column(default_table = params[:controller],default_sort = 'id')
    if params[:sort] and params[:sort][/\./]
      sort = params[:sort].split(".",2)[1].sub('species','specie')
      table = params[:sort].split(".",2)[0]
    else
      sort = default_sort
      table = default_table
    end
    # Make table a copy so modifying it with sub! doesn't modify params[:controller]:
    table = table.clone
    # The search controller uses the traits_and_yields_view table (a view, actually):
    table.sub!('search', 'traits_and_yields_view')
    (eval table
       .classify
       .sub('Method', 'Methods') # We named the model for the methods table 'Methods' (plural), contravening convention.
       .sub('Dbfile', 'DBFile') # We named the model for the dbfiles table 'DBFile' rather than 'Dbfile'.
       .sub('Species', 'Specie') # Rails expects 'Species' (singular) to be the class name for a table called 'species'; but we didn't follow this convention.
     ).column_names.include?(sort) ? "#{table}.#{sort}" : "id"
  end
 
  def sort_direction
    %w[asc desc].include?(params[:direction]) ?  params[:direction] : "asc"
  end

  # Logs searches: who requested the search, the search string, the
  # return format requested, the and SQL query that will be done.
  # (Generally, any order or limit clauses will be ignored.)
  #
  # In the simplest case, a single parameter is passed that is the
  # class of the model for the table being searched.  The model's
  # +search+ method will be called with args (by default,
  # params[:search]) as the argument.
  #
  # If a method is passed as the first argument, it will be called
  # with +arg+ as argument.
  #
  # Finally, if a string is passed as the first arguement, it will be
  # assumed to be the SQL query itself and +args+ is ignored.
  def log_searches(m, arg = params[:search])
    # Get the SQL query for this search:
    case 
    when m.instance_of?(Class) && m.respond_to?(:where)
      # It's a model; do the default thing:
      sql = m.search(arg).to_sql
    when m.instance_of?(Method) && m.respond_to?(:call)
      sql = m.call(arg).to_sql
    when m.instance_of?(String)
      # assume it's the SQL itself
      sql = m
    else
      logger.warn("Bad call to log_searches")
    end

    search_info = "client ip: " + request.remote_ip
    search_info += "\ncurrent user id: " + (current_user && current_user.id.to_s || "(no logged-in user)")
    search_info += "\ncurrent user e-mail: " + (current_user && current_user.email || "(no logged-in user)")
    search_info += "\nsearch string: \"" + (params['search'] || "") + "\""
    search_info += "\nformat: " + (params['format'] || 'html')
    search_info += "\nSQL query: " + sql # method_object.call(arg).send(additional_method).to_sql
    search_info += "\nall parameters: " + params.inspect

    logger.info(search_info)
  end

end

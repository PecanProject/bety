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
    (eval table
       .sub('species', 'specie') # Rails expects 'Species' (singular) to be the class name for a table called 'species'; but we didn't follow this convention.
       .sub('search', 'traits_and_yields_view') # The search controller uses the traits_and_yields_view table (a view, actually).
       .classify
       .sub('Method', 'Methods') # We named the model for the methods table 'Methods' (plural), contravening convention.
       .sub('Dbfile', 'DBFile') # We named the model for the dbfiles table 'DBFile' rather than 'Dbfile'.
     ).column_names.include?(sort) ? "#{table}.#{sort}" : "id"
  end
 
  def sort_direction
    %w[asc desc].include?(params[:direction]) ?  params[:direction] : "asc"
  end

  def log_searches(m, arg = nil)
    # Get the SQL query for this search:
    case 
    when m.instance_of?(Class) && m.respond_to?(:where)
      # It's a model; do the default thing:
      sql = m.search(params[:search]).to_sql
    when m.instance_of?(Method) && m.respond_to?(:call)
      sql = m.call(arg).to_sql
    else
      logger.warn("Bad call to log_searches")
    end

    search_info = "client ip: " + request.remote_ip
    search_info += "\nsearch string: \"" + (params['search'] || "") + "\""
    search_info += "\nformat: " + (params['format'] || 'html')
    search_info += "\nSQL query: " + sql # method_object.call(arg).send(additional_method).to_sql
    search_info += "\nall parameters: " + params.inspect

    logger.info(search_info)
  end

end

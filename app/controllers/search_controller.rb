# This controller handles searches.
include AuthenticatedSystem

class SearchController < ApplicationController
  helper_method :sort_column, :sort_direction

  CREDITS = <<CREDITS
David LeBauer, Michael Dietze, Rob Kooper, Steven Long, Patrick Mulrooney, Gareth Scott Rohde, Dan Wang 2010.\ 
Biofuel Ecophysiological Traits and Yields Database (BETYdb)\
Energy Biosciences Institute, University of Illinois at Urbana-Champaign.\
doi:10.13012/J8H41PB9\
CREDITS
  CREDITS.chomp!

  CONTACT_EMAIL = "dlebauer@illinois.edu"


  # Possible paramaters (params):
  #   set automatically by Rails:
  #     utf8 = [checkmark]
  #     controller = "search"
  #     action = "index"
  #   visible form controls:
  #     search (a string of search terms, possibly empty)
  #     DataTables_Table_0_length (select from 10, 25 (default), 50, 100)
  #   hidden input fields (set by JavaScript):
  #     direction ("asc" or "desc")
  #     sort (name of a column)
  #     lat (latitude of clicked map point)
  #     lng (longitude of clicked map point)
  #     radius (search radius)
  #     searchBySite ("true" or "false")
  #     mapDisplayed (2-valued)
  #     mapZoomLevel (for saving map state)
  #     mapCenterLat (for saving map state)
  #     mapCenterLng (for saving map state)
  #   set by JavaScript in query string:
  #     iteration
  #   set by user in URL query string:
  #     format
  #
  # Instance variables:
  #   @iteration (not clear why this is needed)
  #   @all_marker_locations (city, sitename, lat, and lon for all distinct sites)
  #   @all_result_locations (city, sitename, lat, and lon for all distinct sites in the search results)
  #   @results (all table data for the current page of search results in sorted order)
  def index
    if params[:format].nil? or params[:format] == 'html'
      @iteration = params[:iteration][/\d+/] rescue 1

      # Ensure only permitted access
      all_viewable_rows = TraitsAndYieldsView
        .all_limited(current_user)

      # for making map markers
      @all_marker_locations = all_viewable_rows
        .select("site_id, city, sitename, lat, lon")
        .where("lat IS NOT NULL AND lon IS NOT NULL")
        .group("site_id, city, sitename, lat, lon")

      # intermediate variable used in getting locations in the
      # selected by clicking the map:
      results_in_map_region = all_viewable_rows
        .coordinate_search(params)

      sites_in_map_region = results_in_map_region
        .select("site_id, city, sitename, lat, lon")
        .where("lat IS NOT NULL AND lon IS NOT NULL")
        .group("site_id, city, sitename, lat, lon")
        .to_a
        .map { |row| row.serializable_hash }

      # intermediate variable used in getting result locations and
      # result table data:
      search_results = results_in_map_region
        .search(params[:search])

      
      @all_result_locations = search_results
        .select("site_id, city, sitename, lat, lon")
        .where("lat IS NOT NULL AND lon IS NOT NULL")
        .group("site_id, city, sitename, lat, lon")
        .to_a
        .map { |row| row.serializable_hash }


      @non_map_selected_sites = @all_marker_locations.to_a.map { |row| row.serializable_hash } - sites_in_map_region

      @map_selected_sites_excluded_by_search_terms = sites_in_map_region - @all_result_locations
      
      # for search results table
      @results = search_results
        .sorted_order("#{sort_column('traits_and_yields_view','scientificname')} #{sort_direction}")
        .paginate :page => params[:page], :per_page => params[:DataTables_Table_0_length]

    else # Allow url queries of data, with scopes, only xml & csv ( & json? )
      @results = TraitsAndYieldsView
        .all_limited(current_user)
        .coordinate_search(params)
        .search(params[:search])

    end

    sql_query = log_searches(TraitsAndYieldsView
                               .all_limited(current_user)
                               .coordinate_search(params)
                               .search(params[:search])
                               .to_sql)

    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.xml  { render :xml => @results }
      format.csv do 
        header = CSV.generate do |csv|
          csv << [ "# " + CREDITS ]
          csv << [ "#" ]
          csv << [ "# Contact:", CONTACT_EMAIL ]
          csv << [ "#" ]
          csv << [ "# SQL query:", sql_query ]
          csv << [ "#" ]
          csv << [ "# Date of query:", Time.now ]
          csv << [ "#" ]
        end

        str = header + @results.to_comma
        send_data str, type: Mime::CSV,
        disposition: "attachment; filename=search_results.csv"
      end
      format.json  { render :json => @results }
    end
  end

end

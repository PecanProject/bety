# This controller handles searches.
include AuthenticatedSystem

class SearchController < ApplicationController
  helper_method :sort_column, :sort_direction

  CREDITS = <<CREDITS
LeBauer, David, Michael Dietze, Rob Kooper, Steven Long, Patrick Mulrooney, Gareth Scott Rohde, Dan Wang (2010).  \
Biofuel Ecophysiological Traits and Yields Database (BETYdb), Energy Biosciences Institute, University of Illinois at Urbana-Champaign. \
doi:10.13012/J8H41PB9 \
All public data in BETYdb is made available under the Open Data Commons Attribution License (ODC-By) v1.0. \
You are free to share, create, and adapt its contents. \
Data with an access_level field and value <= 2 is is not covered by this license but may be available for use with consent.
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

    # Set the minimum value for the "checked" attribute:
    if params[:include_unchecked].nil? ||
        !['true', 'TRUE', 'yes', 'YES', 'y', 'Y', '1', 't', 'T',
          'include_unchecked'].include?(params[:include_unchecked])
      checked_minimum = 1
    else
      checked_minimum = 0
    end

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
      rows_in_map_region = all_viewable_rows
        .coordinate_search(params)

      sites_in_map_region = rows_in_map_region
        .select("site_id, city, sitename, lat, lon")
        .where("lat IS NOT NULL AND lon IS NOT NULL")
        .group("site_id, city, sitename, lat, lon")
        .to_a
        .map { |row| row.serializable_hash }

      # intermediate variable used in getting result locations and
      # result table data:
      search_results = rows_in_map_region
        .search(params[:search])
        .checked(checked_minimum)
      
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
        .sorted_order("#{sort_column('traits_and_yields_view', 'sitename')} #{sort_direction}")
        .paginate :page => params[:page], :per_page => params[:DataTables_Table_0_length]

      sql_query = log_searches(TraitsAndYieldsView
                                 .all_limited(current_user)
                                 .coordinate_search(params)
                                 .search(params[:search])
                                 .checked(checked_minimum)
                                 .to_sql)

    elsif params[:format] == 'csv' # Allow url queries of data in csv format
      @results = TraitsAndYieldsView
        .all_limited(current_user)
        .coordinate_search(params)
        .search(params[:search])
        .checked(checked_minimum)
        .order("checked desc")

      sql_query = log_searches(TraitsAndYieldsView
                                 .all_limited(current_user)
                                 .coordinate_search(params)
                                 .search(params[:search])
                                 .checked(checked_minimum)
                                 .to_sql)

    else # Allow url queries of data in xml & json formats
      @results = TraitsAndYieldsView
        .all_limited(current_user)
        .coordinate_search(params)
        .search(params[:search])
        .api_search(params)
        .checked(checked_minimum)


      sql_query = log_searches(TraitsAndYieldsView
                                 .all_limited(current_user)
                                 .coordinate_search(params)
                                 .search(params[:search])
                                 .api_search(params)
                                 .checked(checked_minimum)
                                 .to_sql)

    end

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
          csv << [ "# Time of query:", Time.now.utc ]
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

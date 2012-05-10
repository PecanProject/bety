require 'rvg/rvg'
include Magick

include Mercator
class MapsController < ApplicationController
  layout 'application'
  #before_filter :login_required, :only => ["location_yields","location_yields_lookup"]
#  before_filter :access_conditions

  def location_yields_lookup

    location = County.first(:conditions => ['state like ? and name like ?',params[:state],params[:county]])

    render :update do |page|
      if location and location.location_yields.length > 0
        tmp = ""
        location.location_yields.each do |ly|
          next unless (logged_in? and current_user.page_access_level <= 2) or ly.species == 'miscanthus'
          tmp += "#{ly.species.titleize.sub(" "," - ")}: #{ly.yield.to_f.round(4)}<br/>"
        end
        page.assign 'contentString', "Results for: <strong>#{location.name}, #{location.state}</strong>&nbsp;&nbsp;&nbsp;<br /><hr>#{tmp}"
      else
        page.assign 'contentString', "<strong>#{sanitize(params[:county])}, #{sanitize(params[:state])}</strong><br />No results found!"
      end
    end
  end

  def location_yields_show
    crop = params[:crop]

    render :update do |page|
      page.replace_html 'location_yields_show', :partial => 'location_yields_show', :locals => { :crop => crop }
    end
      
  end

  def location_yields
    params[:fullscreen] ? @fullscreen = true : @fullscreen = false

    @county = County.find(1890) if params[:test]

    respond_to do |format|
      if @fullscreen
       format.html { render "location_yields", :layout => "fullscreen" }
      elsif request.user_agent.include?("iPhone") or request.user_agent.include?("iPad") or request.user_agent.include?("Android") or params[:test] == "iphone"
       format.html { render "location_yields_iphone", :layout => "fullscreen" }
     else
       format.html
      end
    end
  end

  def species_details

    if !params[:search].nil?
      @query = params[:search]
      @species_yields = @species_traits = Specie.all(:conditions => ['scientificname like :query or genus like :query or AcceptedSymbol like :query', {:query => "%#{@query}%"} ],:limit => 100)
    else
      @species_yields = Specie.all(:conditions => ["id in (?)",Yield.all_limited(current_user ||= nil).all(:group => :specie_id,:order => "count(id) DESC",:limit => 10).collect {|x| x.specie_id}])
      @species_traits = Specie.all(:conditions => ["id in (?)",Trait.all_limited(current_user ||= nil).all(:group => :specie_id,:order => "count(id) DESC",:limit => 10).collect {|x| x.specie_id}])
    end

    respond_to do |format|
      format.html
      format.xml  { render :xml => @species_yields }
    end
  end

  def sites_from_search
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  #map showing each site associated with a species
  def sites_by_species
    @species = Specie.find_by_sql("select * from species where id in (select specie_id from yields where site_id IS NOT NULL ) or id in (select specie_id from traits where site_id IS NOT NULL)")

    respond_to do |format|
      format.html 
    end
  end

  # Provides a map populated with sites, then returns trait information if they click on a site
  def traits_from_sites
    @sites = Trait.all.collect {|x| x.site unless x.site.nil?}.compact.uniq
    #@sites = Site.all(:conditions => ['id in (?)', traits.uniq])
 
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # Partial for traits_from_sites
  def show_traits
    site = params[:site]

    @site = Site.find(params[:site])

    if !site.nil?
      @trait = Trait.all_limited(current_user ||= nil).find_all_by_site_id(site, :group => "treatment_id" )
    else
      @trait = []
    end

    @trait_logged_in = Trait.all_limited(current_user ||= nil).find_all_by_site_id(site).length - @trait.length

    render :update do |page|
      page.replace_html 'show_traits', :partial => 'show_traits'
    end
  end

  def traits
    @traits = Trait.all_limited(current_user ||= nil)
    if !params[:site].nil?
      site = Site.find(params[:site])
      @traits = @traits.find_all_by_site_id(site.id)
      @title = site.sitename_state_country
    elsif !params[:species].nil?
      species = Specie.find(params[:species])
      @traits = @traits.find_all_by_specie_id(species.id)
      @title = species.scientificname
    end 
    if params[:format].nil? or params[:format] == 'html'
      @traits = @traits.paginate :page => params[:page]
    end

    respond_to do |format|
      format.html
      format.xml  { render :xml => @traits }
      format.csv  { render :csv => @traits, :style => :maps_traits }
      format.json { render :json => @traits }
    end
  end


  # Provides a map populated with sites, then returns yield information if they click on a site
  def yields_from_sites
    @sites = Yield.all.collect {|x| x.site}.compact.uniq

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # Partial for yields_from_sites
  def show_yields
    site = params[:site] 
    @site = Site.find(params[:site])

    if !site.nil?
      @yields = Yield.all_limited(current_user ||= nil).find_all_by_site_id(@site.id, :group => "treatment_id" )
    else
      @yields = []
    end

    @yields_logged_in = Yield.all_limited(current_user ||= nil).find_all_by_site_id(site).length - @yields.length

    render :update do |page|
      page.replace_html 'show_yields', :partial => 'show_yields'
    end

  end

  def yields
    @yields = Yield.all_limited(current_user ||= nil)
    if !params[:site].nil?
      site = Site.find(params[:site])
      @yields = @yields.find_all_by_site_id(site.id)
      @title = site.sitename_state_country
    elsif !params[:species].nil?
      species = Specie.find(params[:species])
      @yields = @yields.find_all_by_specie_id(species.id)
      @title = species.scientificname
    end
    if params[:format].nil? or params[:format] == 'html'
      @yields = @yields.paginate :page => params[:page]
    end

    respond_to do |format|
      format.html
      format.xml  { render :xml => @yields }
      format.csv  { render :csv => @yields }
      format.json { render :json => @yields }
    end
  end
 
  #partial for sites_by_species  
  def show_sites_by_species
    search_group = params[:sg]
    group_option = params[:go]
    common_name = params[:cn]

    @query = ''

    @sites = []

    if common_name.blank?

      search_group = '1' if !['1','2','3'].include?(search_group)
      group_option = '1' if !['1','2','3','4','5','6'].include?(group_option)
      
      case search_group
        when "1" then case group_option
          when "1" then 
            conditions = 'species.GrowthHabit like "%graminoid%" and species.Duration like "%perennial%" or species.Duration like "%biennial%"'
            @query = "Growth Form - perrenial grass or sedge"
          when "2" then 
            conditions = 'species.GrowthHabit like "%graminoid%" and species.Duration like "%annual%"' 
            @query = "Growth Form - annual grass or sedge"
          when "3" then 
            conditions = 'species.GrowthHabit like "%tree%"' 
            @query = "Growth Form - tree"
          when "4" then 
            conditions = 'species.GrowthHabit like "%shrub%"' 
            @query = "Growth Form - shrub"
          when "5" then 
            conditions = 'species.GrowthHabit like "%forbs%" or species.GrowthHabit like "%herbs%"' 
            @query = "Growth Form - forbs and herbs"
          when "6" then 
            conditions = 'species.GrowthHabit like "%vines%"' 
            @query = "Growth Form - vine"
        end 
        when "2" then case group_option
          when "1" then 
            conditions = 'species.DroughtTolerance like "High" or species.Precipitation_Minimum < 15' 
            @query = "Water Demand - xeric"
          when "2" then 
            conditions = '(species.DroughtTolerance != "High" or Precipitation_Minimum > 15) and (species.NationalWetlandIndicatorStatus not like "%OBL%" and species.NationalWetlandIndicatorStatus not like "%FACW%")' 
            @query = "Water Demand - mesic"
          when "3" then 
            conditions = 'species.NationalWetlandIndicatorStatus like "%OBL%" or species.NationalWetlandIndicatorStatus like "%FACW%"' 
            @query = "Water Demand - hydric"
        end
        when "3" then case group_option
          when "1" then 
            conditions = 'species.TemperatureMinimum > 32' 
            @query = "Climate - tropical"
          when "2" then 
            conditions = 'species.TemperatureMinimum < -50' 
            @query = "Climate - arctic"
          when "3" then 
            conditions = 'species.TemperatureMinimum < 32 and species.TemperatureMinimum > -50' 
            @query = "Climate - temperate"
        end
      end
    else

      if common_name[/[^a-zA-Z\ ]/]
        @query = 'Invalid Search'
      else
        conditions = ['species.CommonName like ? or species.Genus like ?', common_name + "%", common_name + "%"] 
        @query = common_name
      end
    end
         
    @sites = Site.all(:include => {:traits => :specie }, :conditions => conditions, :order => 'sites.country, sites.state, sites.city') 
    render :update do |page|
      page.replace_html 'show_sites_by_species', :partial => 'show_sites_by_species', :locals => { :sites => @sites }
    end
  end


    
 
  def show_sites
    site = true if !params[:lat].nil? and !params[:lng].nil?
    radius = params[:radius].to_i

    if site
      lat = params[:lat].to_f
      lng = params[:lng].to_f
    else
      lat,lng = 0.0,0.0
    end

    #20 miles
    #lat ~ miles/69.1
    #lng ~ miles/53.0
    latminus = lat - (radius/69.1)
    latplus = lat + (radius/69.1)

    lngminus = lng - (radius/53.0)
    lngplus = lng + (radius/53.0)

    if site
      @sites = Site.find_by_sql(["SELECT * FROM sites WHERE lat >= ? AND lat <= ? AND lon >= ? AND lon <= ?", latminus, latplus, lngminus, lngplus])
    else
      @sites = nil
    end


    render :update do |page|
      page.replace_html 'show_sites', :partial => "show_sites"
      page.show 'show_sites'
    end

  end
    

  # GET /maps
  # GET /maps.xml
  def index
    respond_to do |format|
      format.html { redirect_to "/bety" }
      format.xml  { render :xml => @maps }
    end
  end

end

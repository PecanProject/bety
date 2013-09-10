class UsersController < ApplicationController
  
  before_filter :login_required, :except => [:create,:new]
  #before_filter :login_required
  helper_method :sort_column, :sort_direction

  def index
    @iteration = params[:iteration][/\d+/] rescue 1
    if current_user.page_access_level == 1
      @users = User.sorted_order("#{sort_column('users', 'created_at')} DESC").search(params[:search]).paginate(
        :page => params[:page], 
        :per_page => params[:DataTables_Table_0_length]
      )
    else
      @users = User.find(current_user.id)
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

  def show 
    if current_user.page_access_level == 1
      user_id = params[:id]
    else
      user_id = current_user.id
    end
    @user = User.find(user_id)
  end

  def new
    @user = User.new
  end
 
  def create
    logout_keeping_session!
    @user = User.new(params[:user])
    @user.access_level = 3
    @user.page_access_level = 4
    if Rails.env == "test"
      success = @user && @user.save
    else 
      success = verify_recaptcha(:model => @user, :message => "Please re-enter the words from the image again.") && @user && @user.save
    end
    page_access_level = ["", "Administrator", "Manager", "Creator", "Viewer"]
    access_level = ["", "Restricted", "Internal EBI & Collaborators", "External Researchers", "Public"]

    if params[:user][:page_access_level].to_i != 4 or params[:user][:access_level].to_i != 3
      xml = "<issue>"
      xml += "<project name='BETY-db' id='1'/>"
      xml += "<tracker name='Bug' id='1'/>"
      xml += "<status name='New' id='1'/>"
      xml += "<priority name='Normal' id='4'/>"
      xml += "<author name='BETY Bug Report' id='32'/>"
      xml += "<assigned_to id='3'/>"
      xml += "<subject>Access request for #{@user.name.to_xs} (#{@user.login.to_xs})</subject>"
      xml += "<description>https://www.betydb.org/users/#{@user.id}/edit\n"
      xml += "\n"
      xml += "#{@user.name.to_xs} (#{@user.login.to_xs}) has requested a non-default access level.\n"
      xml += "Page_access_level: #{page_access_level[params[:user][:page_access_level].to_i]}\n"
      xml += "Access_level: #{access_level[params[:user][:access_level].to_i]}\n"
      xml += "\n"
      xml += "Reason: #{params[:access_level_reason].to_xs}\n"
      xml += "</description>"
      xml += "</issue>'"

      uri = URI.parse("https://ebi-forecast.igb.illinois.edu/redmine/projects/bety-db/issues.xml")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri.request_uri)
      request.basic_auth "betybug", "ch#pRUr9"
      request.body = xml
      request.content_type = "application/xml"
      response = http.request(request)
    end
    if success && @user.errors.empty?
      # Protects against session fixation attacks, causes request forgery
      # protection if visitor resubmits an earlier form using back
      # button. Uncomment if you understand the tradeoffs.
      # reset session
      self.current_user = @user # !! now logged in
      redirect_to root_path
      flash[:notice] = "Thanks for signing up!"
    else
      flash[:error]  = "We couldn't set up that account, sorry.  Please try again, or contact an admin (link is above)."
      render :action => 'new'
    end
  end

  def edit
    # Allow admins to edit any account, and each user thier own
    if current_user.page_access_level == 1 or params[:id] == current_user.id.to_s
      user_id = params[:id]
    else
      redirect_to edit_user_path(current_user, :id => current_user.id) and return
    end
    @user = User.find(user_id)
  end

  def update
    @user = User.find(params[:id])
    if current_user.page_access_level != 1
      #Prevent user from attempting to submit updated info for a different user if they are not an admin.
      if @user.id != current_user.id
        logger.info "Attempted attack!"
        logger.info params[:user].to_yaml
        redirect_to logout_path and return
      end

      #Prevent users from changing their own access level unless they are admins...
      params[:user].delete(:access_level)
      params[:user].delete(:page_access_level)
    end

    respond_to do |format|
      if @user.update_attributes(params[:user])
        flash[:notice] = 'User was successfully updated.'
        format.html { redirect_to( user_path(@user) ) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

end

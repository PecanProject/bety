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
      @users = User.where("id = #{current_user.id}").paginate(
        :page => params[:page],
        :per_page => params[:DataTables_Table_0_length]
      )
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
    @user.apikey = (0...40).collect { ((48..57).to_a + (65..90).to_a + (97..122).to_a)[Kernel.rand(62)].chr }.join
    if Rails.env == "test"
      success = @user && @user.save
    else
      success = verify_recaptcha(:model => @user, :message => "Please re-enter the words from the image again.") && @user && @user.save
    end
    page_access_level = ["", "Administrator", "Manager", "Creator", "Viewer"]
    access_level = ["", "Restricted", "Internal EBI & Collaborators", "External Researchers", "Public"]

    if success && @user.errors.empty?
      if params[:user][:page_access_level].to_i < 4 or params[:user][:access_level].to_i < 3
        ContactMailer::admin_approval(params[:user], root_url).deliver
      end
      ContactMailer::signup_email(@user, root_url).deliver
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
    # Allow admins to edit any account, and each user their own
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

      # Prevent users from increasing their own access levels beyond the default
      # unless they are admins.  Instead, e-mail a request for more privileged
      # access.
      if params[:user][:page_access_level].to_i < [4, current_user.page_access_level].min or
          params[:user][:access_level].to_i < [3, current_user.access_level].min

        ContactMailer::admin_approval(params[:user], root_url).deliver

        params[:user].delete(:access_level)
        params[:user].delete(:page_access_level)

        privileged_access_requested = true

      end
    end

    respond_to do |format|
      if @user.update_attributes(params[:user])
        if privileged_access_requested
          flash[:notice] = 'Access privilege changes will be submitted for approval.  Other updates were applied.'
        else
          flash[:notice] = 'User was successfully updated.'
        end
        format.html { redirect_to( user_path(@user) ) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  def create_apikey
    user = User.find(params[:user])
    user.create_apikey
    if user.save
      ContactMailer::apikey_email(user).deliver
      flash[:notice] = "A new api key has been created."
    else
      flash[:error] = "Error creating new api key, please try again."
    end
    redirect_to users_path
  end

end

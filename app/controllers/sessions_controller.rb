# This controller handles the login/logout function of the site.
include AuthenticatedSystem
class SessionsController < ApplicationController

  # This should be used on opening the home page ... before a user logs in
  # On attempting to login from this page ... feed it to the create method in this controller
  def new
#    @user.new = User.new
#    @session.new = Session.new
  end

  def create
    logout_keeping_session!
    user = User.authenticate(params[:login], params[:password])
    if user
      # Protects against session fixation attacks, causes request forgery
      # protection if user resubmits an earlier form using back
      # button. Uncomment if you understand the tradeoffs.
      # reset_session
      self.current_user = user
      new_cookie_flag = (params[:remember_me] == "1")
      handle_remember_cookie! new_cookie_flag
      #Next two lines not necessary, all references should be removed. Use 'current_user' instead
#      session[:page_access_requirement] = user.page_access_level
#      session[:access_level] = user.access_level
      redirect_to root_path
      flash[:notice] = "Logged in successfully"
    else
      note_failed_signin
      @login       = params[:login]
      @remember_me = params[:remember_me]
      flash[:notice] = "The login credentials you provided are incorrect."
      render :action => 'new'
    end
  end

  def destroy
    logout_killing_session!
    flash[:notice] = "You have been logged out."
    redirect_to root_path
  end

  # This is made for use from the EBI website
  # urls to this rails application ending in this:
  # /ebi_forwarded/?as@_dlAA5kq
  # Will be automatically logged in with the below defebi_username account
  def ebi_forwarded
#    http://localhost:3000/ebi_forwarded/?email=wongcrott@gmail.com&pass=as@_dlAA5kq

    if params[:pass] == 'as@_dlAA5kq'
      if User.find_by_email(params[:email]).nil?
        @user = User.new(
          :login => params[:email].split('@')[0], 
          :name => params[:email].split('@')[0],
          :email => params[:email],
          :password => "asdfasdf",
          :password_confirmation => "asdfasdf", 
          :access_level => 1,
          :page_access_level => 1
        ).save!
      end
      
      user = User.authenticate( params[:email].split('@')[0], "asdfasdf")
      
#      puts request.query_string.to_s
#      puts user.object_id
      self.current_user = user
      new_cookie_flag = (params[:remember_me] == "1")
      handle_remember_cookie! new_cookie_flag

      session[:page_access_requirement] = current_user.page_access_level
      session[:access_level] = current_user.access_level
      redirect_to root_path
      flash[:notice] = "Welcome EBI user #{current_user.name}"
    else
      redirect_to root_path
      flash[:notice] = 'Please login through the EBI link on page ...'
    end
  end

protected
  # Track failed login attempts
  def note_failed_signin
    flash[:error] = "Couldn't log you in as '#{params[:login]}'"
    logger.warn "Failed login for '#{params[:login]}' from #{request.remote_ip} at #{Time.now.utc}"
  end
end

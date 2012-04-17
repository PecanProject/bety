# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base

  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem
  include Mercator
  require 'csv'

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

#  #sets appropiate access levels for Yield/Trait
#  # return checked value and access_level
#  def access_conditions
#    if logged_in?
#      user = current_user
#      if user.page_access_level == 1
#        $checked = -1
#        $access_level = 1
#      elsif user.page_access_level <= 2
#        $checked = -1
#        $access_level = user.access_level
#        #$access_level = user.page_access_level
#      else
#        $checked = 1
#        $access_level = user.access_level
#        #$access_level = user.page_access_level
#      end
#    else
#      $checked = 1
#      $access_level = 4
#    end
#  end

  #Attempting to not log Maps#mapoverlay
  def silent?(action)
    false
  end

# this knows more than I'd like about the internals of process, but
# the other options require knowing even more.  It would have been
# nice to be able to use logger.silence, but there isn't a good
# method to hook that around, due to the way benchmarking logs.

  def log_processing_with_silence_logs
    if logger && silent?(action_name) then
      @old_logger_level, logger.level = logger.level, Logger::ERROR
    end

    log_processing_without_silence_logs
  end

  def process_with_silence_logs(request, response, method = :perform_action, *arguments)
    ret = process_without_silence_logs(request, response, method, *arguments)
    if logger && silent?(action_name) then
      logger.level = @old_logger_level
    end
    ret
  end

  alias_method_chain :log_processing, :silence_logs
  alias_method_chain :process, :silence_logs

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
end

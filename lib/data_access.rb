module DataAccess
  # Limit search results according to the current user's data access
  # permissions, or, if no user is logged in, limit access to checked
  # data of access level 4.
  #
  # Administrators (that is, users with page_access_level 1) have view
  # access to all data, checked or not.  Managers can access all of
  # this data as well except for data restricted to access_level 1
  # users.  All other users can see only checked data, and only data
  # with a access level number at least as high as the user's access
  # level number.  Notwithstanding these restrictions, all users have
  # access to data marked with their user id.
  #
  # == Usage
  #
  # class MyModel < ActiveRecord::Base
  #   extend DataAccess
  #   (...)
  # end
  #
  # class ControllerForMyModel < ApplicationController
  #   def my_search_method(params...)
  #     @results = MyModel.all_limited(current_user)...
  #     (...)
  #   end
  #   (...)
  # end
  #
  # It is assumed MyModel has a user_id column, an access_level
  # column, and a checked column.
  #
  def all_limited(current_user)
    if !current_user.nil?
      if current_user.page_access_level == 1
        checked = -1
        access_level = 1
      elsif current_user.page_access_level <= 2
        checked = -1
        access_level = current_user.access_level
      else
        checked = 1
        access_level = current_user.access_level
      end
      user = current_user
    else
      user = 1000000000000
      checked = 1
      access_level = 4
    end

    where("(checked >= ? and access_level >= ?) or user_id = ?",checked,access_level,user)
  end

end

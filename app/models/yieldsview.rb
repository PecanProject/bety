class Yieldsview < ActiveRecord::Base
  set_table_name 'yieldsview'

  scope :all_limited, lambda { |current_user|
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

    {:conditions => ["(checked >= ? and access_level >= ?) or user_id = ?",checked,access_level,user] }
  }

  comma do
    yield_id
    citation_id
    site_id
    site
    lat
    lon
    sp
    author
    cityear
    trt
    date
    month
    year
    mean
    n
    statname
    stat
    notes
    user
  end

end


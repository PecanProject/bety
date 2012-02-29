# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def access_level(id)
    access = ["", "Restricted", "Internal EBI & Collaborators", "External Researchers", "Public"]
    return access[id.to_i]
  end

  def page_access_requirement(id)
    access = ["", "Administrator", "Manager", "Creator", "Viewer"]
    return access[id.to_i]
  end

  $dateloc_drop = {  "4   time of day, e.g. morning, afternoon" => "4.0" ,
                     "5   day" => "5.0" ,
                     "5.5 week " => "5.5",
                     "6   month" => "6.0" ,
                     "6.5 " => "6.5" ,
                     "7   season" => "7.0" ,
                     "7.5 " => "7.5" ,
                     "8   year" => "8.0" ,
                     "9   no data" => "9.0"  }
  $timeloc_drop = {  "1   second" => "1.0" ,
                     "2   minute" => "2.0" ,
                     "2.5 quarter-hour" => "2.5" ,
                     "3   hour" => "3.0" }
end

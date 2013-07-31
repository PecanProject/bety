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
  # Checks if current treatment_id is in associated citations treatment
  # association.
  def treatment_check(ty)
    if ty.citation
      if ty.treatment.nil?
        return
      elsif !ty.citation.treatments.include?(ty.treatment)
        ": <span class='red_back'>treatment_id: #{ty.treatment.id}, not in associated citation associated treatments!</span>"
      end
    end
        
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

  $statname_list =  ["","SD", "SE", "MSE", "95%CI", "LSD", "MSD", "P", "HSD"]


  # Simple Search
  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = (column == sort_column) ? "current #{sort_direction}" : nil
    direction = (column == sort_column && sort_direction == "asc") ? "desc" : "asc"
    link_to title, params.merge(:sort => column, :direction => direction, :page => nil), {:class => css_class}
  end
end

# Call this to make a link inside a form that submits the form.
def link_to_submit(*args, &block)
  link_to_function (block_given? ? capture(&block) : args[0]), "jQuery(this).closest('form').submit()", args.extract_options!
end

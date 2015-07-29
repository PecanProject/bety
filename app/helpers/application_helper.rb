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
  $dateloc_drop_default = "9.0"
  $timeloc_drop = {  "1   second" => "1.0" ,
                     "2   minute" => "2.0" ,
                     "2.5 quarter-hour" => "2.5" ,
                     "3   hour" => "3.0" ,
                     "9   no data" => "9.0"  }
  $timeloc_drop_default = "9.0"

  $statname_list =  ["","SD", "SE", "MSE", "95%CI", "LSD", "MSD"]


  # Simple Search
  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = (column == sort_column) ? "current #{sort_direction}" : nil
    direction = (column == sort_column && sort_direction == "asc") ? "desc" : "asc"
    link_to title, params.merge(:sort => column, :direction => direction, :page => nil), {:class => css_class}
  end

  def format_stat(record)
    if (record.statname!=nil && !record.statname.empty? && record.stat!=nil)
      if (record.n!=nil)
        "#{record.statname}&nbsp;=&nbsp;#{record.stat}, n&nbsp;=&nbsp;#{record.n}".html_safe
      else
         "#{record.statname}&nbsp;=&nbsp;#{record.stat}".html_safe
      end
    else
      if(record.n!=nil)
        "n&nbsp;=&nbsp;#{record.n}".html_safe
      end
    end
  end

end

# Call this to make a link inside a form that submits the form.
def link_to_submit(*args, &block)
  link_to_function (block_given? ? capture(&block) : args[0]), "jQuery(this).closest('form').submit()", args.extract_options!
end

# Given a FormBuilder object `f`, a string `label`, a SQL table name
# `table_name`, a symbol `id`, and a string `placeholder`, make an
# autocompletion field with id "search_#{table_name}", an associated label with
# text `label`, and an associated hidden field that will use a parameter name
# derived from `id`.  The text of `placeholder` will appear in the
# autocompletion field, and the field will have class `autocompletion_class` or
# "input-full" if not given.
#
# In order that this be recognized as an autocompletion field, the template for
# the page using this helper should include a "content_for" block of the form
#
# <% content_for(:autocomplete_javascript) do %>
#     <script type="text/javascript" charset="utf-8">
#         var ROOT_URL = '<%= root_url %>';
#         var completion_fields = {
#             <id of autocompletion field>: {
#                 controller:
#                     <controller portion of URL for the controller whose autocomplete action is called>,
#                 hidden_field_id:
#                     <id of associated hidden field> },
#             ...
#         }
#   </script>
#   <%= javascript_include_tag 'lazy/autocomplete.js' %>
# <% end %>
def autocompletion_field(f, label, table_name, id, placeholder, autocompletion_class = "input-full")
  autocompletion_field_id = "search_".concat(table_name).to_sym
  (label_tag autocompletion_field_id, label).
    concat(text_field_tag(autocompletion_field_id, "",
                          placeholder: placeholder,
                          class: autocompletion_class)).
    concat(f.hidden_field id)
end

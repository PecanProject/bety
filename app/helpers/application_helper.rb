# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  DATA_ACCESS_LEVELS = [ ["1. Restricted", 1], ["2. Internal & Collaborators", 2], ["3. External Researcher", 3], ["4. Public", 4] ]
  ABBREVIATED_DATA_ACCESS_LEVELS = [ ["1. Restricted", 1], ["2. Internal", 2], ["3. External", 3], ["4. Public", 4] ]
  DEFAULT_DATA_ACCESS_LEVEL = 3 # External Researcher
  UNNUMBERED_DATA_ACCESS_LEVELS_WITH_BLANK = [ ["", 0], ["Restricted", 1], ["Internal & Collaborators", 2], ["External Researcher", 3], ["Public", 4] ]

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
    link_to title, params.permit(:sort, :direction, :page, :_).merge(:sort => column, :direction => direction, :page => nil), {:class => css_class}
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
  link_to (block_given? ? capture(&block) : args[0]), "#", args.extract_options!.merge(onclick: "jQuery(this).closest('form').submit(); return false")
end

# Given a FormBuilder object `f`, a string `label`, an SQL table name
# `table_name`, a symbol `id`, and a string `placeholder`, make an
# autocompletion field with id "search_#{table_name}", an associated label with
# text `label`, and an associated hidden field that will use a parameter name
# derived from `id`.  If given, the text of `display_value` will appear in the
# autocompletion field.  Otherwise, an attempt is made to find text representing
# the current value (if any) and display it.  If there is no current value, the
# text of `placeholder` will appear.  The field will have class
# `autocompletion_class`, or "input-full" if not given.
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
def autocompletion_field(f, label, table_name, id, placeholder, display_value = nil, autocompletion_class = "input-full")
  if display_value.nil?
    begin
      associated_entity_or_self = f.object.send(table_name.singularize)
    rescue
      associated_entity_or_self = f.object
    end
    if associated_entity_or_self.nil?
        display_value = ""
    else
      begin
        display_value = associated_entity_or_self.autocomplete_label
      rescue
        display_value = associated_entity_or_self.to_s.squish
      end
    end
  end
  autocompletion_field_id = "search_".concat(table_name).to_sym
  (label_tag autocompletion_field_id, label).
    concat(text_field_tag(autocompletion_field_id, display_value,
                          placeholder: placeholder,
                          class: autocompletion_class)).
    concat(f.hidden_field id)
end

def commit_is_tagged?
  !commit_tags.blank?
end

def commit_tags
  e = ENV['BETY_GIT_TAGS']
  ref_names = e.nil? || e.empty? ? `git log --pretty=format:"%d" -1` : e
  if /tag/.match(ref_names).nil?
    return ""
  end

  # If we required a version of Git recent enough to support the %D placeholder,
  # we wouldn't need the following line:
  ref_names.sub!(/ *\(([^)]*)\) */, '\1')

  ref_array = ref_names.split(',')
  ref_array.keep_if { |ref| /tag/.match(ref) }
  ref_array.collect! { |ref| ref.sub(/tag: *(.*) */, '\1') }
  ref_array.join(', ')
end

def commit_branch
  e = ENV['BETY_GIT_BRANCH']
  e.nil? || e.empty? ? `git rev-parse --abbrev-ref HEAD` : e
end

def commit_checksum
  e = ENV['BETY_GIT_CHECKSUM']
  e.nil? || e.empty? ? `git log --pretty=format:"%H" -1` : e
end

def commit_date
  e = ENV['BETY_GIT_DATE']
  e.nil? || e.empty? ? `git log --pretty=format:"%ad" -1` : e
end

# Replacement for the Prototype method of this name.
def observe_field(element_id, **options)
  # We assume options has either the key :url or the key :function (but not
  # both).
  if options.has_key? :url
    url = url_for(options[:url])
    connector = url.match(/\?/) ? '&' : '?'
    raw(
      %Q{<script>
             jQuery(document).ready(function() {
                 jQuery("##{element_id.to_s}").bind("keyup", function() {
                     jQuery.post("#{url}" + "#{connector}" + #{options[:with]})
                 })
             })
         </script>}
      ).html_safe
  else
    raw(
      %Q{<script>
             jQuery(document).ready(function() {
                 jQuery("##{element_id.to_s}").bind("keyup", function() {
                     #{options[:function]}
                 })
             })
         </script>}
      ).html_safe
  end
end

# Dummy method to replace Prototype method of this name.  Needs to be fleshed
# out.
def submit_to_remote(a, b, c)
  'Create'
end

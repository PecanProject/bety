module BulkUploadHelper

  MAXIMUM_ERRORS_TO_DISPLAY_PER_TYPE = 10

  # maps data reference errors to appropriate page for finding or
  # adding referents
  ERROR_REMEDY_MAP = {
    unresolvable_citation_reference: { link_url: :citations, link_text: "Search for or add citation" },
    unresolvable_site_reference: { link_url:  :sites, link_text: "Search for or add site" },
    unresolvable_species_reference: { link_url:  :species_index, link_text: "Search for or add species" },
    unresolvable_treatment_reference: { link_url: :treatments, link_text: "Search for or add treatment" },
    unresolvable_cultivar_reference: { link_url: :cultivars, link_text: "Search for or add cultivar" }
  }

  # Used by the +display_csv_file+ template.
  def make_validation_summary
    summary = "" # default to empty string if no errors
    if @data_set.file_has_fatal_errors

      summary = content_tag :div, class: "fade in alert alert-error centered" do
        div = "Your file contains #{pluralize(@data_set.total_error_count, "error")}."
        div << "<br>You can not upload your data set until #{@data_set.total_error_count > 1 ? "these are" : "this is"} corrected."
        raw div
      end
      
      summary += content_tag :div, id: "error_explanation" do
        contents = raw ''
        if @data_set.field_list_error_count > 0
          contents += content_tag :h2, "Field List Errors"

          contents += content_tag :ul do
            list_items = "".html_safe
            @data_set.validation_summary[:field_list_errors].each do |message|
              list_items += content_tag :li, "* " + message
            end
            list_items
          end # content_tag :ul
        end # if @data_set.field_list_error_count > 0

        if @data_set.data_value_error_count > 0
          contents += content_tag :h2, "Data Value Errors"

          contents += content_tag :ul do
            list_items = "".html_safe
            @data_set.validation_summary.each_pair do |key, value|
              if key == :field_list_errors
                next
              end

              row_info = ''
              if value.has_key?(:row_numbers)
                row_list = value[:row_numbers]
                row_list.uniq!
                suffix = ''
                if row_list.size > MAXIMUM_ERRORS_TO_DISPLAY_PER_TYPE
                  row_list = row_list[0..10]
                  suffix = ' ...'
                end
                row_info += " in these rows: " + row_list.map { |row_no| link_to row_no, anchor: "row_#{row_no}" }.join(', ') + suffix
                if ERROR_REMEDY_MAP.has_key?(key)
                  # provide a link to page to search for or add
                  # missing referent:
                  row_info << (link_to ERROR_REMEDY_MAP[key][:link_text], ERROR_REMEDY_MAP[key][:link_url])
                end
              end

              list_items += content_tag :li, class: value[:css_class] do
                li_content = "* " + key + row_info
                raw li_content
              end
            end # each_pair do
            list_items
          end # content_tag :ul
        end # if @data_set.data_value_error_count > 0

        contents
      end # content_tag :div

    end # if @data_set.file_has_fatal_errors
    return summary
  end

  def make_warning_summary
    summary = "" # default to empty string if no warnings
    if  @data_set.csv_warnings.any?
      summary = content_tag :div, id: "warning_explanation" do
        div_content = content_tag :h2, "Warnings"
        div_content += content_tag :ul do
          list_items = "".html_safe
          @data_set.csv_warnings.each do |msg|
            list_items += content_tag :li, raw("* #{msg}") # use raw because msg may contain markup
          end
          list_items
        end
        div_content
      end
    end
    return summary
  end

  def get_access_level(session)
     [nil, 'Restricted', 'Internal EBI & Collaborators', 'External Researcher', 'Public'][session[:global_values][:access_level].to_i] rescue nil
  end

end

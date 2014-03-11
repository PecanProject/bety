module BulkUploadHelper
  ERROR_MESSAGE_MAP = {
    negative_yield: "Negative value for yield",
    unparsable_yield: "Yield value can't be parsed as a number",
    unresolvable_citation_reference: "Unresolvable citation reference",
    future_citation_year: "Citation year is in the future",
    too_old_citation_year: "Citation year is too far in the past",
    unparsable_citation_year: "Citation year can't be parsed as an integer",
    unresolvable_site_reference: "Unresolvable site reference",
    inconsistent_site_reference: "Inconsistent site reference",
    unresolvable_species_reference: "Unresolvable species reference",
    unresolvable_treatment_reference: "Unresolvable treatment reference",
    inconsistent_treatment_reference: "Inconsistent treatment reference",
    unparsable_access_level: "Access level can't be parsed as an integer",
    unresolvable_cultivar_reference: "Unresolvable cultivar reference",
    unacceptable_date_format: "Unacceptable date format",
    future_date: "Date is in the future",
    invalid_date: "Date is invalid",
    invalid_sample_size: "Invalid sample size (n)",
    unparsable_sample_size: "Sample size (n) can't be parsed as an integer",
    unparsable_standard_error_value: "Standard error value (SE) can't be parsed as a number"
  }

  # maps data reference errors to appropriate page for finding or
  # adding referents
  ERROR_REMEDY_MAP = {
    unresolvable_citation_reference: { link_url: :citations, link_text: "Search for or add citation" },
    unresolvable_site_reference: { link_url:  :sites, link_text: "Search for or add site" },
    unresolvable_species_reference: { link_url:  :species_index, link_text: "Search for or add species" },
    unresolvable_treatment_reference: { link_url: :treatments, link_text: "Search for or add treatment" },
    unresolvable_cultivar_reference: { link_url: :cultivars, link_text: "Search for or add cultivar" }
  }

  def make_validation_summary
    summary = "" # default to empty string if no errors
    if @data_set.file_has_fatal_errors
      
      summary = content_tag :div, id: "error_explanation", style: "width:850px; margin: auto" do
        contents = content_tag :div, class: "fade in alert alert-error centered" do
          div = "Your file contains #{pluralize(@data_set.total_error_count, "error")}."
          div << "<br>You can not upload your data set until #{@data_set.total_error_count > 1 ? "these are" : "this is"} corrected."
          raw div
        end
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
              if ERROR_MESSAGE_MAP.has_key?(key)
                list_items += content_tag :li do
                  li_content = "* " + ERROR_MESSAGE_MAP[key]
                  li_content << " in these rows: " + value.map { |row_no| link_to row_no, anchor: "row_#{row_no}" }.join(', ')
                  if ERROR_REMEDY_MAP.has_key?(key)
                    # provide a link to page to search for or add
                    # missing referent:
                    li_content << (link_to ERROR_REMEDY_MAP[key][:link_text], ERROR_REMEDY_MAP[key][:link_url])
                  end
                  raw li_content
                end
              end # if .. has_key?
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
      summary = content_tag :div, id: "warning_explanation", style: "width:850px; margin:auto" do
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

end

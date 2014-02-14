module BulkUploadHelper
  INTERACTIVE_COLUMNS = %w{site species treatment access_level cultivar date}

  def need_interactively_specified_data
    missing_columns = INTERACTIVE_COLUMNS - @headers
  end

  def need_citation_selection
    @headers.select { |field| field =~ /citation_/ }.empty? && session['citation'].nil?
  end

  ERROR_MESSAGE_MAP = {
    negative_yield: "Negative value for yield",
    unparsable_yield: "Yield value can't be parsed as a number",
    unresolvable_citation_reference: "Unresolvable citation reference",
    future_citation_year: "Citation year is in the future",
    too_old_citation_year: "Citation year is too far in the past",
    unparsable_citation_year: "Citation year can't be parsed as an integer",
    unresolvable_site_reference: "Unresolvable site reference",
    unresolvable_species_reference: "Unresovable species reference",
    unresolvable_treatment_reference: "Unresolvable treatment reference",
    unparsable_access_level: "Access level can't be parsed as an integer",
    unresolvable_cultivar_reference: "Unresolvable cultivar reference",
    unacceptable_date_format: "Unacceptable date format",
    future_date: "Date is in the future",
    invalid_date: "Date is invalid",
    invalid_sample_size: "Invalid sample size (n)",
    unparsable_sample_size: "Sample size (n) can't be parsed as an integer",
    unparsable_standard_error_value: "Standard error value (SE) can't be parsed as a number"
  }

  def make_validation_summary
    summary = "" # default to empty string if no errors
    if @file_has_fatal_errors
      
      summary = content_tag :div, id: "error_explanation", style: "width:850px; margin: auto" do
        contents = content_tag :div, "Your file contains #{pluralize(@total_error_count, "error")}.", class: "fade in alert alert-error centered"
        if @field_list_error_count > 0
          contents += content_tag :h2, "Field List Errors"

          contents += content_tag :ul do
            list_items = "".html_safe
            @validation_summary[:field_list_errors].each do |message|
              list_items += content_tag :li, "* " + message
            end
            list_items
          end # content_tag :ul
        end # if @field_list_error_count > 0

        if @data_value_error_count > 0
          contents += content_tag :h2, "Data Value Errors"

          contents += content_tag :ul do
            list_items = "".html_safe
            @validation_summary.each_pair do |key, value|
              if ERROR_MESSAGE_MAP.has_key?(key)
                list_items += content_tag :li, "* " + ERROR_MESSAGE_MAP[key] + " in these rows: " + value.join(', ')
              end # if .. has_key?
            end # each_pair do
            list_items
          end # content_tag :ul
        end # if @data_value_error_count > 0

        contents
      end # content_tag :div

    end # if @file_has_fatal_errors
    return summary
  end

  def make_warning_summary
    summary = "" # default to empty string if no warnings
    if  @csv_warnings.any?
      summary = content_tag :div, id: "warning_explanation", style: "width:850px; margin:auto" do
        div_content = content_tag :h2, "Warnings"
        div_content += content_tag :ul do
          list_items = "".html_safe
          @csv_warnings.each do |msg|
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

jQuery(function() {
    // initialize any and all autocompletion fields found on the page:

    // to-do: options should be restricted by citation choosen
    jQuery('#autocomplete_site').autocomplete({
        source: ROOT_URL + "/sites/bu_autocomplete.json"
    });

    jQuery('#autocomplete_species').autocomplete({
        source: ROOT_URL + "/species/bu_autocomplete.json",

        // update source for the cultivars fields: cultivar suggestions depend on what species was chosen
        change: function(event, ui) {
            jQuery('#autocomplete_cultivar').autocomplete("option", "source", ROOT_URL +
                                                          "/cultivars/bu_autocomplete.json?species=" +
                                                          encodeURIComponent(jQuery('#autocomplete_species').val()))
        }
    });

    // to-do: options should be restricted by citation choosen
    jQuery('#autocomplete_treatment').autocomplete({
        source: ROOT_URL + "/treatments/bu_autocomplete.json"
    });


    // Set the cultivar autocompletion list based upon whether or not the user has chosen a species:
    if (jQuery('#autocomplete_species').val() == '') {
        optionList = [{ label: "Please choose a species", value: null}]
    }
    else {
        // We only get here in the case the species value was prepopulated at the time the page was loaded.
        optionList = (ROOT_URL + "/cultivars/bu_autocomplete.json?species=" +
                      encodeURIComponent(jQuery('#autocomplete_species').val()))
    }
    jQuery('#autocomplete_cultivar').autocomplete({
        // set source to this until it gets updated by the species field change method
        source: optionList
    });


    // for choose_global_citation page:
    jQuery('#autocomplete_citation').autocomplete({
        source: ROOT_URL + "/citations/bu_autocomplete.json"
    });

    jQuery('#autocomplete_citation').on("autocompleteselect", function(e, ui) {

        // Prevent the value of the item selected from displaying after a
        // selection has been made ...
        e.preventDefault();

        // ... and display the *value* of the item selected instead ...
        this.value = ui.item.label;

        // ... but store the value of the item selected in a hidden field.
        jQuery('#global_values_citation_id').val(ui.item.value);
    });

    jQuery("form").submit(function(event, ui) {
        var allowSubmission = true;

        for (autocompletion_widget_id in bu_completion_fields) {
            allowSubmission = allowSubmission && bu_completion_fields[autocompletion_widget_id]["valid"];
        }

        return allowSubmission;
    });

    for (autocompletion_widget_id in bu_completion_fields) {
        jQuery('#' + autocompletion_widget_id).autocomplete({
            minLength: 0,
            source: ROOT_URL + "/methods/bu_autocomplete.json",
            select: create_select_function(autocompletion_widget_id),
            focus: function(event, ui) {
                // Prevent the value (the id number) of an item selected from
                // displaying when using the arrow keys:
                event.preventDefault();
            },
            change: create_change_function(autocompletion_widget_id)
        });
        jQuery('#' + autocompletion_widget_id).click(create_click_function(autocompletion_widget_id));

    }

});

function create_select_function(autocompletion_widget_id) {
    return function(event, ui) {
        // Prevent the value (the id number) of the item selected from
        // displaying after a selection has been made ...
        event.preventDefault();

        // ... and display the *label* of the item selected instead ...
        var display = ui.item.label;
        // ... unless it's "[no value]"; then just display the placeholder.
        if (ui.item.label == "[no value]") {
            display = "";
        }
        jQuery(this).val(display);

        // Clear the error message if present:
        jQuery('label[for = "' + autocompletion_widget_id + '"] span.error').hide();

        // Save the selected values in the session, both for making
        // values "sticky" and for use by subsequent pages of the
        // wizard:
        jQuery.post(ROOT_URL + "/bulk_upload/store_trait_method_mapping_in_session",
                    {
                        "trait_name": event.target.id,
                        "method_info": {
                            "label": display,
                            "value": ui.item.value
                        }
                    });

    }
}

function create_change_function(autocompletion_widget_id) {
    return function(event, ui) {
        var validValue = (ui.item != null && ui.item.label != null);

        if (validValue) {
            jQuery('label[for = "' + autocompletion_widget_id + '"] span.error').hide();
        }
        else {
            jQuery('label[for = "' + autocompletion_widget_id + '"] span.error').show();

            jQuery(this).select();
        }
        bu_completion_fields[autocompletion_widget_id]["valid"] = validValue;
    }
}

function create_click_function(autocompletion_widget_id) {
    return function(event, ui) {
        jQuery('#' + autocompletion_widget_id).select();
        jQuery('#' + autocompletion_widget_id).autocomplete("search");
    }
}

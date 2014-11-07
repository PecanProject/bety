jQuery(function() {
    // initialize any and all autocompletion fields found on the page:

    // to-do: options should be restricted by citation choosen
    jQuery('#autocomplete_site').autocomplete({
        source: ROOT_URL + "/sites/autocomplete.json"
    });

    jQuery('#autocomplete_species').autocomplete({
        source: ROOT_URL + "/species/autocomplete.json",

        // update source for the cultivars fields: cultivar suggestions depend on what species was chosen
        change: function(event, ui) {
            jQuery('#autocomplete_cultivar').autocomplete("option", "source", ROOT_URL +
                                                          "/cultivars/autocomplete.json?species=" +
                                                          encodeURIComponent(jQuery('#autocomplete_species').val()))
        }
    });

    // to-do: options should be restricted by citation choosen
    jQuery('#autocomplete_treatment').autocomplete({
        source: ROOT_URL + "/treatments/autocomplete.json"
    });


    // Set the cultivar autocompletion list based upon whether or not the user has chosen a species:
    if (jQuery('#autocomplete_species').val() == '') {
        optionList = [{ label: "Please choose a species", value: null}]
    }
    else {
        // We only get here in the case the species value was prepopulated at the time the page was loaded.
        optionList = (ROOT_URL + "/cultivars/autocomplete.json?species=" +
                      encodeURIComponent(jQuery('#autocomplete_species').val()))
    }
    jQuery('#autocomplete_cultivar').autocomplete({
        // set source to this until it gets updated by the species field change method
        source: optionList
    });


    // for choose_global_citation page:
    jQuery('#autocomplete_citation').autocomplete({
        source: ROOT_URL + "/citations/autocomplete.json"
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

});

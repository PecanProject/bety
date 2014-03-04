jQuery(function() {
    // initialize any and all autocompletion fields found on the page:

        jQuery('#autocomplete_site').autocomplete({
            source: ROOT_PATH + "/sites/autocomplete.json"
        });

        jQuery('#autocomplete_species').autocomplete({
            source: ROOT_PATH + "/species/autocomplete.json",

            // update source for the cultivars fields: cultivar suggestions depend on what species was chosen
            change: function(event, ui) {
                jQuery('#autocomplete_cultivar').autocomplete("option", "source", ROOT_PATH + "/cultivars/autocomplete.json?species=" + jQuery('#autocomplete_species').val())
            }
        });

        jQuery('#autocomplete_treatment').autocomplete({
            source: ROOT_PATH + "/treatments/autocomplete.json"
        });

        jQuery('#autocomplete_cultivar').autocomplete({
            // set source to this until it gets updated by the species field change method
            source: function(request, response) {
                // no matter what the user types, this option will be all that is displayed until a species is chosen
                response([{ label: "Please choose a species", value: null}])
            }
        });

});

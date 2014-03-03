jQuery(function() {


    if (jQuery('#autocomplete_site').length) {
        var sites;
        jQuery.get("/sites/autocomplete.json", function( data ) {
            sites = data;
        });

        jQuery('#autocomplete_site').autocomplete({
            
            source: function(request, response) {
                var matcher = new RegExp("^" + jQuery.ui.autocomplete.escapeRegex( request.term ), "i" );
                
                response( jQuery.grep( sites, function( item ) {
                    return matcher.test( item );
                }) );
            }
        });
    }


    if (jQuery('#autocomplete_species').length) {
        /*
        var species;
        jQuery.get("/species/autocomplete.json", function( data ) {
            species = data;
        });
        */
        jQuery('#autocomplete_species').autocomplete({
            /*
            source: function(request, response) {
                var matcher = new RegExp("^" + jQuery.ui.autocomplete.escapeRegex( request.term ), "i" );
                
                response( jQuery.grep( species, function( item ) {
                    return matcher.test( item );
                }) );
            }
            */
            source: "/species/autocomplete.json"
        });
    }


    if (jQuery('#autocomplete_treatment').length) {
        var treatments;
        jQuery.get("/treatments/autocomplete.json", function( data ) {
            treatments = data;
        });

        jQuery('#autocomplete_treatment').autocomplete({
            
            source: function(request, response) {
                var matcher = new RegExp("^" + jQuery.ui.autocomplete.escapeRegex( request.term ), "i" );
                
                response( jQuery.grep( treatments, function( item ) {
                    return matcher.test( item );
                }) );
            }
        });
    }


    if (jQuery('#autocomplete_cultivar').length) {
        var cultivars;
        jQuery.get("/cultivars/autocomplete.json", function( data ) {
            cultivars = data;
        });

        jQuery('#autocomplete_cultivar').autocomplete({
            
            source: function(request, response) {
                var matcher = new RegExp("^" + jQuery.ui.autocomplete.escapeRegex( request.term ), "i" );
                
                response( jQuery.grep( cultivars, function( item ) {
                    return matcher.test( item );
                }) );
            }
        });
    }



    

});

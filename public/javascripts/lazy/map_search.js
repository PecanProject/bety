// Once map display button is loaded, add a click event to it:
jQuery( function() {

    jQuery("#toggle_map_display").click(function() {
        if ( jQuery( "#map_canvas" ).is( ":hidden" ) ) {

            jQuery( "#map_canvas" ).show();
            jQuery("#toggle_map_display").text("Hide Map")

            // Put the Google Map in the canvas if it hasn't been done:
            if (!jQuery( "#map_canvas" ).get(0).hasChildNodes()) {
                loadMap();
            }

        } else {

            jQuery( "#map_canvas" ).hide();
            jQuery("#toggle_map_display").text("Show Map")

            // Drop location restriction from search and update search results:
            jQuery( "#radius" ).removeAttr("value");
            search_function( { radius: null } );

        }
    });
});
                
// Loads the map into the map_canvas element and adds a click event listener to it.
function loadMap() {
    
    var mapOptions = {
        zoom: 4,
        center: new google.maps.LatLng(40.44,-95.98),
        mapTypeId: google.maps.MapTypeId.ROADMAP
    };

    map = new google.maps.Map($("map_canvas"), mapOptions);

    overlay = [];

    google.maps.event.addListener(map, "click", function(event) {
        if (overlay.length > 0) {
            overlay[0].setMap(null);
            overlay.length = 0;
        }

        // Store page parameters in local variables
        var radius = ($('radius') && $('radius').value) || 200;
        var lat = event.latLng.lat();
        var lon = event.latLng.lng();

        // Increment the iteration number in the simple_search_table class name on each search
        var iteration = parseInt(jQuery('#simple_search_table').attr('class').match(/\d+/)[0]) + 1;
        jQuery('#simple_search_table').removeClass();
        jQuery('#simple_search_table').addClass('simple_search_table_' + iteration);

        var mapSearchParams =  { lat: lat, lng: lon, radius: radius };

        // Pass the map search parameters to simple_search's
        // search_function where they will be combined with search term
        // parameters from the search form:
        search_function(null, mapSearchParams);

        // Adjust the overlay according to the value of the radius and the click coordinates
        var latOffset = radius/(69.1);
        var lonOffset = radius/(53.0);
        var paths = [new google.maps.LatLng(lat + latOffset, lon + lonOffset),
                     new google.maps.LatLng(lat - latOffset, lon + lonOffset),
                     new google.maps.LatLng(lat - latOffset, lon - lonOffset),
                     new google.maps.LatLng(lat + latOffset, lon - lonOffset),
                     new google.maps.LatLng(lat + latOffset, lon + lonOffset)];
        overlay.push( new google.maps.Polygon({
            paths: paths,
            strokeColor: "#ff0000",
            strokeWeight: 0,
            strokeOpacity: 1,
            fillColor: "#ff0000",
            fillOpacity: 0.2,
            clickable: false,
            map: map
        }))

    });

}


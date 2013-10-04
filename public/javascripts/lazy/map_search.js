var overlay;

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

            if (overlay.length > 0) {
                overlay[0].setMap(null);
                overlay.length = 0;
            }

            // reset hidden input fields
            jQuery("#simple_search #mapZoomLevel").val(null);
            jQuery("#simple_search #mapCenterLat").val(null);
            jQuery("#simple_search #mapCenterLng").val(null);

            
        }
    });
});

// Loads the map into the map_canvas element and adds a click event listener to it.
function loadMap() {

    var zoom = parseInt(jQuery("#simple_search #mapZoomLevel").val()) || 3;
    var centerLat = parseInt(jQuery("#simple_search #mapCenterLat").val()) || 44;
    var centerLng = parseInt(jQuery("#simple_search #mapCenterLng").val()) || -30;
    
    var mapOptions = {
        zoom: zoom,
        center: new google.maps.LatLng(centerLat, centerLng),
        mapTypeId: google.maps.MapTypeId.ROADMAP
    };

    map = new google.maps.Map($("map_canvas"), mapOptions);
    addMarkers();
    overlay = [];

    google.maps.event.addListener(map, "click", searchByRegion);

    google.maps.event.addListener(map, 'bounds_changed', function() {
        var zoomLevel = map.getZoom();
        var mapCenter = map.getCenter();
        console.log(mapCenter.toString());

        jQuery("#simple_search #mapZoomLevel").val(zoomLevel);
        jQuery("#simple_search #mapCenterLat").val(mapCenter.lat());
        jQuery("#simple_search #mapCenterLng").val(mapCenter.lng());

    });


    

}

function searchBySite(event) {
    searchByLocation(event, true);
}

function searchByRegion(event) {
    searchByLocation(event, false);
}

function searchByLocation(event, searchingBySite)  {

    // Store page parameters in local variables
    var lat = event.latLng.lat();
    var lon = event.latLng.lng();
    var radius;
    // use the value from the radius element if it exist, otherwise 200 (miles)
    var radiusElt = $('radius');
    radius = radiusElt ? radiusElt.value : 200;

    // Increment the iteration number in the simple_search_table class name on each search
    var iteration = parseInt(jQuery('#simple_search_table').attr('class').match(/\d+/)[0]) + 1;
    jQuery('#simple_search_table').removeClass();
    jQuery('#simple_search_table').addClass('simple_search_table_' + iteration);

    var mapSearchParams =  { lat: lat, lng: lon, radius: radius, searchingBySite: searchingBySite };

    // Pass the map search parameters to simple_search's
    // search_function where they will be combined with search term
    // parameters from the search form:
    search_function(null, mapSearchParams);

    // UPdate the overlay:
    removeOverlay();
    if (!searchingBySite) {
        addOverlay(lat, lon, radius);
    }
}

function removeOverlay() {
    if (overlay.length > 0) {
        overlay[0].setMap(null);
        overlay.length = 0;
    }
}

function addOverlay(lat, lon, radius) {
    
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
    }));
}

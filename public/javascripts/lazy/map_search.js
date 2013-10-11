var overlay;

// Once map display button is loaded, add a click event to it:
jQuery( function() {

    // Add handler for the "Clear Map" button: It should remove the
    // overlay (if there is one), set the search mode state variable
    // to "off", and update the search results.
    jQuery("#remove_map_location_filter").click(function() {
        if (jQuery("#simple_search #mapSearchMode").val() == "by region") {
            removeOverlay();
        }
        jQuery("#simple_search #mapSearchMode").val("off");
        // redo search based only on contents of text box:
        search_function();
    });

    jQuery("#toggle_map_display").click(function() {
        if ( jQuery( "#map_canvas" ).is( ":hidden" ) ) {

            jQuery( "#map_canvas" ).show();
            jQuery( "#remove_map_location_filter" ).show();
            jQuery("#simple_search #mapDisplayed").val("true");
            jQuery("#toggle_map_display").text("Hide Map")

            // Put the Google Map in the canvas if it hasn't been done:
            if (!jQuery( "#map_canvas" ).get(0).hasChildNodes()) {
                loadMap();
            }

            // Ensure markers are colored according to search results:
            updateMarkers();
            
            // Do a search if we have stored location parameters:

            var lat = jQuery("#simple_search #lat").val();
            var lng = jQuery("#simple_search #lng").val();
            var radius = jQuery("#simple_search #radius").val();

            if (lat && lng && radius) {
                var mapSearchParams =  { lat: lat,
                                         lng: lng,
                                         radius: radius,
                                         mapSearchMode: jQuery("#simple_search #mapSearchMode").val() };

                search_function(null, mapSearchParams);
            }

        } else {

            jQuery( "#map_canvas" ).hide();
            jQuery( "#remove_map_location_filter" ).hide();
            jQuery("#simple_search #mapDisplayed").val("false");
            jQuery("#toggle_map_display").text("Show Map")

            search_function();

        }
    });

    if (jQuery("#simple_search #mapDisplayed").val() == "true") {
        jQuery("#toggle_map_display").click();
    }
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

    map.controls[google.maps.ControlPosition.RIGHT_BOTTOM].push(makeLegend());
    
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

function makeLegend(){
    var legend = document.createElement('div');
    legend.setAttribute('id', 'legend')
    legend.setAttribute('style', "backgroundColor: white; padding: 10px;");

    var images = ['images/redball.png', 'images/yellowball.png','images/whiteball.png']
    var text = ['Selected Sites Matching Search', 'Selected Sites Not Matching Search', 'Sites Outside Search Area']
    for (i = 0;  i < images.length; ++i) {
        var itemdiv = document.createElement('div');
        var image = document.createElement('img');
        image.setAttribute('src', images[i]);
        var explanation = document.createElement('span');
        explanation.innerHTML = text[i];
        itemdiv.appendChild(image);
        itemdiv.appendChild(explanation);
        
        legend.appendChild(itemdiv);
    }
    return legend;
}

function searchBySite(event) {
    searchByLocation(event, "by site");
}

function searchByRegion(event) {
    searchByLocation(event, "by region");
}

function searchByLocation(event, mapSearchMode)  {

    jQuery('#simple_search #mapSearchMode').val(mapSearchMode);

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

    var mapSearchParams =  { lat: lat, lng: lon, radius: radius, mapSearchMode: mapSearchMode };

    // Pass the map search parameters to simple_search's
    // search_function where they will be combined with search term
    // parameters from the search form:
    search_function(null, mapSearchParams);

    // UPdate the overlay:
    removeOverlay();
    if (mapSearchMode == "by region") {
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

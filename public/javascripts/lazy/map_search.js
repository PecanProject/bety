// Once map_canvas element is loaded, fill in the map and add a click event listener.
onload = function() {

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

        // Update the search results
        jQuery.get(ajax_url, { lat: lat, lng: lon, radius: radius,
                    search_type: "map search",
                    iteration: iteration }, null, 'script');

        var latOffset = radius/(69.1);
        var lonOffset = radius/(53.0);
        var paths = [new google.maps.LatLng(lat + latOffset, lon + lonOffset),
                     new google.maps.LatLng(lat - latOffset, lon + lonOffset),
                     new google.maps.LatLng(lat - latOffset, lon - lonOffset),
                     new google.maps.LatLng(lat + latOffset, lon - lonOffset),
                     new google.maps.LatLng(lat + latOffset, lon + lonOffset)];

        // Adjust the overlay according to the value of the radius and the click coordinates
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


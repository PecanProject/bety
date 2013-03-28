// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults




function initalize_google_map(lat, lng, zoom) {
  var type = $(document).find('.map_type_selector.active').html().toLowerCase();

  var minZoomLevel = 2;
  var geocoder;
  var address;
  var latlng = new google.maps.LatLng(31,-15);
  var myOptions = {
    zoom: minZoomLevel,
    streetViewControl: false,
    mapTypeControl: false,
    panControl: false,
    center: latlng,
    mapTypeId: google.maps.MapTypeId.ROADMAP
  };
  var overlayOptions = {
    opacity: 0.6,
  }

  // Google coordinate plane increases in the positive number direction left to right
  map = new google.maps.Map(document.getElementById("map_canvas"), myOptions);

  // setup of vegtype map  
  var vegtype_bounds = new google.maps.LatLngBounds(
    new google.maps.LatLng(-59,-176.8), // south-west
    new google.maps.LatLng(84,179) // north-east
//        new google.maps.LatLng(-50,-124.8), // south-west
//        new google.maps.LatLng(80,115) // north-east  

  );
  var vegtype = new google.maps.GroundOverlay( '../miscanthus_yield_grid.png', vegtype_bounds, overlayOptions );
 
  // clear out existing biome matches
  //$('div[id*="_biomes"]').hide();
  $('div[id*="_biomes"]').find('.biomes').html("");
  
  
  vegtype.setMap(map);
  
  
  //overlay = [];
  
  // Bounds for A single map
   var strictBounds = new google.maps.LatLngBounds(
     new google.maps.LatLng(-70, -170), // bottom-left
     new google.maps.LatLng(70, 170)   // top-right
   );

   // Listen for the map click events
   google.maps.event.addListener(map, 'dragend', function() {
     if (strictBounds.contains(map.getCenter())) return;

     // We're out of bounds - Move the map back within the bounds
     var c = map.getCenter(),
         x = c.lng(),
         y = c.lat(),
         maxX = strictBounds.getNorthEast().lng(),
         maxY = strictBounds.getNorthEast().lat(),
         minX = strictBounds.getSouthWest().lng(),
         minY = strictBounds.getSouthWest().lat();

     if (x < minX) x = minX;
     if (x > maxX) x = maxX;
     if (y < minY) y = minY;
     if (y > maxY) y = maxY;

     map.setCenter(new google.maps.LatLng(y, x));
   });

  // Limit the zoom level
  google.maps.event.addListener(map, 'zoom_changed', function() {
    if (map.getZoom() < minZoomLevel) map.setZoom(minZoomLevel);
  });
  
  markersArray = [];
  google.maps.event.addListener(vegtype, "click", function(event) {

    var lat = event.latLng.lat();
    var lng = event.latLng.lng();

    // clear out existing biome matches
    $('#biome_input_container').find('div.well:not(.inactive_site)').find('div[class*="_biomes"]').find('.biome_list').html("");

    populate_html_from_latlng( lat, lng );

    // for offline testing
//     populate_html_from_latlng( 39.16113, -4.978971 );
    
  });
};

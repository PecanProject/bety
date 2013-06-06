jQuery(document).ready(function(){ 

  var map;
  function initialize() {

    var geocoder;
    var address;
    var latlng = new google.maps.LatLng(40.44,-95.98);
    var myOptions = {
      zoom: 2,
      center: latlng,
      mapTypeId: google.maps.MapTypeId.ROADMAP
    };

    var map = new google.maps.Map(document.getElementById("map_canvas"), myOptions);
    var markersArray = [];
    
    

    jQuery.get("/sites.json", function( data ){
      jQuery.each( data, function ( siteKey, siteValue ){
      
        if ( siteValue.site.lat && siteValue.site.lon ){
          var site_id = siteValue.site.id;

          // generate a new marker
          var marker = new google.maps.Marker({ 
            position: new google.maps.LatLng( siteValue.site.lat , siteValue.site.lon ),
            title: siteValue.site.map_marker_name,
            map: map
          });
          // push marker into storage array
          markersArray[site_id] = marker; 
          
          google.maps.event.addListener( markersArray[site_id], "click", function() {             
            // populate partial for yields at a given site
            jQuery.post("/maps/show_yields", { site: site_id });
            
          });
        
        } // siteValue.lat 
      
      });    
    });

  }

initialize();
        
        
        
});










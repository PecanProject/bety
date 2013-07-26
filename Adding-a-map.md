To add a new map to the betydb 'model projections' maps page, you should first import the data into google fusion tables and create/style the map you want to show. You may want to merge your data with a census table containing kml data for each county and its shape, if you have county-level data.


'Export' your map and hit 'show html and javascript'. Take note of the portion in the middle that looks a bit like this:

>     layer = new google.maps.FusionTablesLayer({
>       map: map,
>       heatmap: { enabled: false },
>       query: {
>         select: "col16\x3e\x3e1",
>         from: "1iTbzIeHyhHtOEYUqxPe8uTVeLG8v4nndHZ_qj88",
>         where: ""
>       },
>       options: {
>         styleId: 25,
>         templateId: 25
>       }
>     });



Paste this section at the end of the function initialize() in the public/javascripts/maps.js file. Change the map property to null and the layer assignment to 

> layers[some number] = new google.maps.FusionTablesLayer(...)

The index you give the new map should be unique. 

If you are trying to add an image, copy one of the other image maps in the maps.js file and update the file path for the image itself and layers table index it is saved under. 

In apps/views/maps/location_yields.html.erb add a new option to the id="selectmap select tag. Set the value equal the index of your new map in the layers table. 

Except for the legend, you're now done! you should be able to view your map on the google maps canvas by selecting it in the dropdown menu.

Under the updatemap() function in maps.js add another else if clause to build the legend. If your map requires a legend for a yield map, the makeyieldlegend helper function can do it for you. The second argument is the maximum yield possible, so that the colors can be assigned correctly. If you need a more exotic legend, you will have to write a snippet of javascript to generate it yourself. The legend div itself is persistent, but it is emptied of children every time the map is changed. 
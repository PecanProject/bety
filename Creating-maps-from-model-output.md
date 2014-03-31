## ArcGIS online

This is an instruction for creating maps on ArcGIS Online.  

1. Sign into https://univofillinois.maps.arcgis.com/home/signin.html  
1. Click on the “My Content” button of the top ribbon. 
1. Click on “Create Map”   
1. Click on the “Basemap” button and select desired basemap. 
1. Select the Add+ button to insert layers. For a .csv file saved on the computer select “Add Layer from File”
1. Left pane of the screen shows 3 buttons. The second button will show the contents (layers) of the map. Here you can make certain layers visible/invisible if desired. The drop down button next to each layer provides options to changing the display. For example, you can change the symbols depicting the coordinates, the information displayed when a coordinate is chosen, and perform analysis if needed. 
1. Save the map with a title, tags, and summary. 
1. To share the map, select share and choose whom to share it to or copy the link.  

This is an instruction for creating maps from arc map 10.1 and uploading it to arcgis online account 
####For creating maps from your arcmap 10.1 on your desktop: (I will work on this when my arcmap resumes)

1. Upload your csv data
1. display your data (first lon, then lat, then field. must choose WGS1984 projection)
1. Upload a mask file (us or world maps)
1. select interpolation from spatial analyst tool from arc tool box (IDW method has been chosen for the past. Take the csv feature file as input)
1. Select extraction from spatial analyst tool from arc tool box (extract by a mask has been chosen for the past. Take the interpolated file as input)
1. save the map as a arcmap

** Make sure you sign in arcgis from your arcmap**

1. Start ArcMap and open the map you want to publish.
1. Click File > Sign In.
1. Type your name and password for ArcGIS Online, then click Sign In.

### Publishing a hosted tiled map service using a tile package

(see [ArcGIS website](http://resources.arcgis.com/en/help/arcgisonline/index.html#/Publishing_a_hosted_feature_service_to_ArcGIS_Online_using_an_ArcMap_document/010q00000087000000/):

ArcGIS for Desktop allows you to build tiles for a map document and store them in an easily transferrable tile package (.tpk) file. You can share a tile package on ArcGIS Online and choose to publish it as a hosted tiled map service. This workflow allows you to build the tiles using your own computing power, rather than your ArcGIS Online credits.

Follow these steps to publish a hosted tiled map service using a tiled package:

1. Open your map in ArcMap and ensure that it's using the WGS 1984 Web Mercator (Auxiliary Sphere) coordinate system.
1. Click Customize > ArcMap Options > Sharing and ensure that Enable ArcGIS Runtime tools is checked.
This enables the menu option you'll use in the next step.
1.    In ArcMap, click File > Share As > Tile Package.
1.    Configure all the settings in the substeps below. Other settings are left to your choosing.
1.        In the Tile Package tab, choose Upload package to my ArcGIS Online account.
1.        In the Tile Format tab, choose ArcGIS Online / Bing Maps / Google Maps as the Tiling Scheme.
1.        In the Item Description tab, provide the items marked as required.
1.        In the Sharing tab, make sure that the connection information for your ArcGIS Online account is correct.
1.    Click Share.

@@@@@@@@@@@ tips
One tip for creating tile package, when you edit the tile format, choose the highest level of detail smaller than the default, which is 20. I chose 10, which gives us enough details and allows us to create a tile within minutes.

You may be prompted to save your map before the tile package can be created.
It can take a while for a tile package to be generated, especially if you have included large scales.

#################################publish online

1. When your tile package has finished generating, log in to your ArcGIS Online organizational account and click My Content.
1.    Click your tile package to display its item details page.
1.    Click Publish.
1.    Type a title and tags and click Publish.
      The tiles are unpacked and hosted as a service. You should be able to see the service in the My Content page.

Once you've verified the service is running, you can optionally delete the original tile package so that you don't have to pay credits to store it.

Now you can add the newly generated tile to a map (either existed or new)

Open the map, click content, you should be able to see all the layers of the tile
Click the layer for which you want to pop-up data, then select "enable pop-up"

from the new enable pop up window, select the features you created before from a csv file.

######################################################################





##  Google Fusion Tables

1. Format data as desired (this will be the same table that users will see in tooltips and download)
** numbers should have appropriate precision (e.g. two decimal places by default)

###  County Level Data

1. Create a column in Excel called "County State", 
2. fill it with the equations `=concatenate(<col with county>, " ", <col with state>)`
3. save as .csv
1. Open [Google Drive](http://drive.google.com)
2. Create new Fusion Table
3. Upload Data 
4. File -> Geocode
5. Set Location Column to "County State"


h3. Gridded Data

* TBD
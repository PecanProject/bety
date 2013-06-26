h2. Google Fusion Tables

1. Format data as desired (this will be the same table that users will see in tooltips and download)
** numbers should have appropriate precision (e.g. two decimal places by default)

h3. County Level Data

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

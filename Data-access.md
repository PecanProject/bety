<a id="Section 4.3"></a>  
### Data Access

Data is made available for analysis after it is submitted
and reviewed by a database admistrator. These data are suitable for
basic scientific research and modeling. All reviewed data are made
publicly available after publication to users of BETY-db who are
conducting primary research. Access to these raw data is provided to
users based on affiliation and contribution of data.

####Search Box

####Advanced Search

####Access Maps

There are five different search methods that can be utilized under the Maps tab:

#####1. Sites by Species

Groups can be searched by selecting criteria from a drop-down menu or a common name or genus can be entering in the search bar below the map.  Both methods of search show the location of the site on the map and location details underneath the map.

#####2. Search for Sites

Utilizing the drop-down menu for radius distances of 20, 40, 60, 80, 100, or 200 miles and then clicking on a location on the map presents sites within that range.  Site city, state, country, latitude, longitude, mean annual temperature, mean annual precipitation, and elevation are shown under the map for each site.  

#####3. Location Yield

The Location Yield map narrows model output by yield, evapotranspiration, and production cost.  Yield and evapotranspiration can be narrowed by species and then county (displays longitude, latitude, and yield in text format) or gridded (displays state, county, and yield in a text format).  Production cost can yield county data, as well as a least cost yield listing.  A fullscreen button enables viewing of the map in greater detail.       

#####4. Traits from Sites

The Traits from Sites map displays all of the sites that have trait data in the database.  Clicking on the site provides the name of the site, and the species/multiple species, cultivar, and citation affiliated with that site, all of which link to more detailed information.  The traits link connects to a full listing of traits for that site with all available information for the traits.    

#####5. Yields from Sites

#####Download Data from Model Output

Data can be downloaded directed by selecting the download button when the desired data is presented in the model.  The data with a title will be downloaded.  

#### URL-based Queries

##### Easy CSV downloads

Data can be downloaded as a `.csv=` file, and data from previously
published syntheses can be downloaded without login. For example, to
download all of the Switchgrass (*Panicum virgatum* L.) yield data,

1.  Open the BETY homepage [www.betydb.org](https://www.bety.org/)
2.  Select [Species](https://www.betydb.org/maps/species_details) under BETYdb
3.  Select [Yields](https://www.betydb.org/maps/yields?species=938) under BETYdb
4.  To download all records as a comma-delimited (`.csv`) file, scroll down and select the link
    <http://ebi-forecast.igb.uiuc.edu/bety/maps/yields?format=csv\&species=938> *(In CSV Format)

#### JSON, CSV, and XML API 

The format of your request will need to be:

BetyDB has the ability to return any object in these three formats. All
the tables in BetyDB are RESTful, which allows you to GET, POST, PUT, or
DELETE them without interacting with the web interface. Here are some
examples:

1. https://www.betydb.org/citations.json 
    Return all citations in json format (replace json with xml or csv for those formats)
2. https://www.betydb.org/citations.json?journal=Agronomy%20Journal 
    Return all citations with the field journal equal to ‘Agronomy Journal’ 
3.  https://www.betydb.org/citations.json?journal=Agronomy%20Journal&author=Adler 
    Return all citations with the field journal equal to ‘Agronomy Journal’ and author equal to ‘Adler’ (sorry no ability to combine with ‘or’ yet) 
4.  https://www.betydb.org/citations.json?include[]=sites 
    Return all citations with their associated sites (you use the singular version of the associated tables name - site - when the relationship is many to one, and the plural when many to many; hint: if the id of the table you are attempting to include is in the record - relatedtable_id - then it is the singular version. 
5.  https://www.betydb.org/citations.json?include[]=sites&include[]=yields 
    Return all citations with their associated sites and yields (working on ability to nest this deeper)
6.  https://www.betydb.org/citations.json?journal=Agronomy%20Journal&author=Adler&include[]=sites&include[]=yields 
    Return all citations with the field journal equal to ‘Agronomy Journal’ and author equal to ‘Adler’ with their associated sites and yields.
7.  https://www.betydb.org/citations/1.json 
    Return citation 1 in json format, can also be achieved by adding ’?id=1’ to line 1
8.  https://www.betydb.org/citations/1.json?include[]=sites 
    Return citation 1 in json format with it’s associated sites
9.  https://www.betydb.org/citations/1.json?include[]=sites&include[]=yields 
    Return citation 1 in json format with it’s associated sites and yields

#### API keys

Using an API key allows access to data without having to enter a login. To use an API key, simply append @?key=<your_api_key>@ to the end of the URL. Each user must obtain a unique API key. 
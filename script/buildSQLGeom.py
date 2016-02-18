#!/usr/bin/env python

"""
This module will accept (x,y,[z]) coordinates (from CSV-format file or cmd arguments)
and generate a SQL string that will add these coordinates as a PostGIS Polygon
to sites.geometry within a BETYdb instance.
A header row should be included in the input file, although the column names do not matter. If a z column
for altitude is not included, the script will attempt to get it from USGS NED (US) or Google (global).
Command line usage:
        -h      show help
        -i      input filename; will override x,y,z args if provided
        -x      longitude value, if no file provided
        -y      latitude value, if no file provided
        -z      altitude value, if no file provided
        -r      EPSG reference number, default is 4326
        -s      sitename or numerical id in BETYdb sites table to associate geometry with.
                If a string is provided, id will be looked up with a query. If an int is provided, id is assumed.
        -o      flag to write resulting SQL to output file, as "<input_filename>_insert.sql"
        -e      will attempt to execute resulting SQL on db instance defined in next 4 params
        -n      PostgreSQL host address; default is Unix-domain socket to server on localhost, if available, otherwise "localhost"
        -d      Database name, default is 'bety'
        -u      Username
        -p      Password
Examples:
        buildSQLGeom.py -i /rel/or/abs/path/to/coordinates.csv -r 4326 -s 19000000000 -e -n localhost -d bety -u GUEST -p GUES -o - sitename "Danforth"
        buildSQLGeom.py -x 76.116081 -y 42.794448 -s 3
Sample input files that are both valid:
        LONGITUDE,LATITUDE,ALTITUDE
        -76.116081,42.794448,415
        -76.116679,42.794448,415
        -76.116679,42.79231,415
  Or:
        X,Y
        -76.116081,42.794448
        -76.116679,42.794448
        -76.116679,42.79231
"""

import sys
import getopt
import requests
import psycopg2

def getDatabaseConnection(host, dbname, user, passwd):
        """
        Get a database connection to the specified host and database with given credentials.
        :param host: Host address of target PostgreSQL instance
        :param dbname: Database to execute query in
        :param user: Username
        :param passwd: Password
        :raises psycopg2.OperationalError: if the connection fails
        """

        print("Connecting to database %s on host %s" % (dbname, host))

        conn = psycopg2.connect(host = host, database = dbname, user = user, password = passwd)

        print("Sucessfully connected to database {0} on host {1}.".format(dbname, host))
        return conn


def getSiteID(sitename, host, dbname, user, passwd):
        """
        Get the id of the site with the given sitename in the BETYdb instance pointed to by host/dbname.
        If the connection fails, return 0.
        If multiple sites or no site has the given sitename, print an error message and exit.
        :param sitename: string representing sitename column in sites table
        :param host: Host address of target PostgreSQL instance
        :param dbname: Database to execute query in
        :param user: Username
        :param passwd: Password
        :return: the site id as a string
        """

        try:
                conn = getDatabaseConnection(host, dbname, user, passwd)
        except psycopg2.OperationalError:
                print("Couldn't connect to database to get site id.")
                print("Using 0 in place of actual value.")
                site_id = 0
        else:
                cur = conn.cursor()
                cur.execute("SELECT id FROM sites WHERE sitename = %s", (sitename,))

                if cur.rowcount == 0:
                        sys.exit("\nThe database contains no site with sitename '{0}'.\n"
                                 "Please be sure you have spelled the site name correctly\n".format(sitename))
                elif cur.rowcount > 1:
                        sys.exit("\nThe database contains multiple sites having sitename '{0}'.\n"
                                 "Sitenames should be unique.  "
                                 "Please correct this problem and\nre-run this script.\n".format(sitename))

                (site_id,) = cur.fetchone()

                cur.close()
                conn.close()

        return site_id

def getUSGSAltitude(x, y, units="Meters"):
        """
        Send a GET request to USGS Elevation Point Query Service to get altitude at given lat/lon.
                Requires requests: http://docs.python-requests.org/en/latest/
                API source: http://ned.usgs.gov/epqs/
        :param x: Longitude coordinate
        :param y: Latitude coordinate
        :param units: Can be Meters or Feet, defaults to Meters
        :return: Altitude in requested units, or None if query fails
        """

        sess = requests.Session()
        get_args = "x="+str(x)+"&y="+str(y)+"&units="+units+"&output=json"
        alt_req = sess.get("http://ned.usgs.gov/epqs/pqs.php?"+get_args)

        if alt_req.status_code == 200:
                # Extract elevation value from response object if successful
                try:
                        res = alt_req.json()['USGS_Elevation_Point_Query_Service']['Elevation_Query']['Elevation']
                except ValueError:
                        res = '-1000000'
                return res
        else:
                return '-1000000'

def getGoogleAltitude(x,y):
        """
        Send a GET request to Google Maps Elevation API to get altitude at given lat/lon.
                Requires requests: http://docs.python-requests.org/en/latest/
                API source: https://developers.google.com/maps/documentation/elevation/intro
        :param x: Longitude coordinate
        :param y: Latitude coordinate
        :return: Altitude in meters, or None if query fails
        """

        # Read Google Maps Elevation API key from file (should be only contents in file)
        # https://developers.google.com/maps/documentation/elevation/get-api-key
        api_key_file = r"GOOGLE_ELEVATION_API_KEY.txt"

        api_file = open(api_key_file, 'r')
        google_api_key = api_file.readline().rstrip()
        api_file.close()

        sess = requests.Session()
        get_args = "locations="+str(y)+","+str(x)+"&key="+google_api_key
        alt_req = sess.get("https://maps.googleapis.com/maps/api/elevation/json?"+get_args)

        if alt_req.status_code == 200:
                # Extract elevation value from response object if successful
                return alt_req.json()['results'][0]['elevation']
        else:
                return None

def main(argv):
        # These are default values, will be overwritten by command line parameters if given.
        input_file = None
        lon        = None
        lat        = None
        alt        = None
        srid       = 4326
        site_id    = False
        sitename   = False

        out_file   = False
        run_query  = False
        # BETYdb instance details
        host       = 'localhost'
        dbname     = 'bety'
        user       = None
        passwd     = 'PASSWORD'

        # Parse command line parameters
        try:
                opts, args = getopt.getopt(argv, "hi:x:y:z:r:s:oen:d:u:p:",
                                           ["input=","lon=","lat=","alt=","srid=","site=","output=","execute","host=","dbname=", "user=", "pass="])
        except getopt.GetoptError:
                print(__doc__)
                sys.exit(2)
        for opt, arg in opts:
                if opt == '-h':
                        import os
                        os.execlp('pydoc', '', 'buildSQLGeom')
                        # os.system('pydoc buildSQLGeom | head -n 47')
                        # sys.exit(0)
                elif opt in ("-i", "--input"):
                        input_file = arg
                elif opt in ("-x", "--lon"):
                        lon = arg
                elif opt in ("-y", "--lat"):
                        lat = arg
                elif opt in ("-z", "--alt"):
                        alt = arg
                elif opt in ("-r", "--srid"):
                        srid = arg
                elif opt in ("-s", "--site"):
                        # Try to interpret site as a string; if it fails, assume this is a sitename
                        try:
                                site_id = int(arg)
                        except ValueError:
                                sitename = arg
                elif opt in ("-o", "--output"):
                        out_file = True
                elif opt in ("-e", "--execute"):
                        run_query = True
                elif opt in ("-n", "--host"):
                        host = arg
                elif opt in ("-d", "--dbname"):
                        dbname = arg
                # TODO: Use default path if no user and password provided
                # http://www.peterbe.com/plog/connecting-with-psycopg2-without-a-username-and-password
                # http://stackoverflow.com/questions/15692437/ident-connection-fails-via-psycopg2-but-works-via-command-line
                elif opt in ("-u", "--user"):
                        user = arg
                elif opt in ("-p", "--pass"):
                        passwd = arg
        if input_file == None and (lon == None or lat == None):
                print('input file is required if no coordinates provided. -h for help.')
                sys.exit(2)

        if not site_id:
                if not host:
                        print('site_id cannot be queried without BETYdb host and credentials. using 0 as default.')
                        site_id = 0
                else:
                        site_id = getSiteID(sitename, host, dbname, user, passwd)
        if out_file:
                # Use input filename with "_insert.sql"
                input_ext = input_file[input_file.rfind("."):]
                out_file = input_file.replace(input_ext, "_insert.sql")

        # Generate query by iterating through input file contents
        query = "UPDATE sites SET geometry = ST_Geomfromtext('POLYGON(("

        if input_file != None:
                # Pull coordinates list from input CSV-format file
                csv = open(input_file, 'r')

                # Examine header to attempt to determine ordering of fields
                headers = csv.readline().rstrip().split(",")
                lon_col, lat_col, alt_col = -1, -1, -1
                unassigned_cols = [i for i in range(len(headers))]
                for column in range(len(headers)):
                        col_name = headers[column].strip().lower()
                        if col_name in ["longitude", "long", "lon", "x"]:
                                lon_col = column
                                print("found longitude in column "+str(column)+': "'+headers[column].strip()+'"')
                                unassigned_cols.remove(column)
                        elif col_name in ["latitude", "lat", "y"]:
                                lat_col = column
                                print("found latitude in column "+str(column)+': "'+headers[column].strip()+'"')
                                unassigned_cols.remove(column)
                        elif col_name in ["altitude", "elevation", "alt", "elev", "z"]:
                                alt_col = column
                                print("found elevation in column "+str(column)+': "'+headers[column].strip()+'"')
                                unassigned_cols.remove(column)
                # If we checked all the headers and didn't find lon/lat, assign to unidentified columns in order
                while (lon_col==-1 or lat_col==-1):
                        if len(unassigned_cols)==0:
                                print('lat and lon columns could not be identified. not enough columns.')
                                sys.exit(2)
                        # Don't automatically assume altitude is a column if not found, since we can query for it
                        if lon_col == -1:
                                lon_col = unassigned_cols[0]
                                unassigned_cols.remove(column)
                        elif lat_col == -1:
                                lon_col = unassigned_cols[0]
                                unassigned_cols.remove(column)

                # The first coordinates provided must also be the last - copy it if raw data doesn't have this
                l = csv.readline().rstrip()
                line_index = 2
                first_coords = None
                while l:
                        # Get values from each row of file separated by ',' and append to query
                        coords = l.split(",")

                        lon = coords[lon_col].strip()
                        lat = coords[lat_col].strip()
                        q_line = lon + " " + lat
                        if len(coords) == 2 or alt_col == -1:
                                # No altitude has been provided; attempt to fetch it
                                if alt == None:
                                        alt = getUSGSAltitude(lon, lat)
                                        if alt == '-1000000':
                                                # These coordinates are outside USGS domestic boundary - Google has global coverage
                                                alt = getGoogleAltitude(lon, lat)
                                if alt and alt!="":
                                        q_line += " " + str(alt)
                        else:
                                if coords[alt_col]!="":
                                        q_line += " " + coords[alt_col].strip()
                                else:
                                        print("line "+str(line_index)+": altitude column empty, querying for elevation value.")
                                        alt = getUSGSAltitude(lon, lat)
                                        if alt == '-1000000':
                                                # These coordinates are outside USGS domestic boundary - Google has global coverage
                                                alt = getGoogleAltitude(lon, lat)
                                        q_line += " " + str(alt)

                        if not first_coords:
                                first_coords = q_line

                        query += q_line

                        # Get next data line and close out query if we reached end of input file
                        l = csv.readline().rstrip()
                        line_index += 1
                        if l:
                                # Include a trailing comma unless we're on the final set of coordinates
                                query += ","
                        else:
                                # Last set of coordinates; do they match the first set? If not, repeat first set.
                                if q_line != first_coords:
                                        query += "," + first_coords
                csv.close()
        else:
                # Use lat/lon provided in command line arguments
                q_line = lon + " " + lat
                if alt == None:
                        # No altitude has been provided; attempt to fetch it
                        alt = getUSGSAltitude(lon, lat)
                        if alt == '-1000000':
                                # These coordinates are outside USGS domestic boundary - Google has global coverage
                                alt = getGoogleAltitude(lon, lat)
                if alt:
                        q_line += " " + str(alt)
                query += q_line

        # Finish the end of the query and print to console
        query += "))', "+str(srid)+") WHERE ID="+str(site_id)

        print("-----")
        print(query)
        print("-----")

        # Write to output file if enabled
        if out_file:
                sqltxt = open(out_file, 'w')
                sqltxt.write(query)
                sqltxt.close()
                print("Query output written to "+out_file)

        # Try to execute query if enabled
        if run_query:
                try:
                        conn = getDatabaseConnection(host, dbname, user, passwd)
                except psycopg2.OperationalError:
                        sys.exit("Couldn't connect to database to run update statement.")
                else:
                        cur = conn.cursor()
                        try:
                                cur.execute(query)
                                if cur.rowcount == 1:
                                        print("One row was updated.")
                                else:
                                        print("{0} rows were updated.".format(cur.rowcount))
                                conn.commit() # changes will be rolled back unless you have this
                        except psycopg2.ProgrammingError:
                                sys.exit("Couldn't execute query \"{0}\".".format(query))
                        finally:
                                cur.close()
                                conn.close()

if __name__ == "__main__":
        main(sys.argv[1:])

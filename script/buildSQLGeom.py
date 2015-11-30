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
        -s      sitename or site_id in BETYdb sites table to associate geometry with.
                if a string is provided, site_id will be queried. if an int is provided, site_id is assumed.
        -o      flag to write resulting SQL to output file, as "<input_filename>_insert.sql"
        -e      will attempt to execute resulting SQL on db instance defined in next 4 params
        -n      PostgreSQL host address
        -d      Database name, default is 'bety'
        -u      Username
        -p      Password

Examples:
        buildSQLGeom.py -i C:/folder/coordinates.csv -r 4326 -s 19000000000 -e -n localhost -d bety -u GUEST -p GUES -o - sitename "Danforth"
        buildSQLGeom.py -x 76.116081 -y 42.794448 -site_id 3

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
#import psycopg2

def executeSQL(query, host, dbname, user, passwd, return_results=False):
        """
        Execute SQL query on specified host database with given credentials.
                Requires psycopg2: https://pypi.python.org/pypi/psycopg2 (un-comment line 32!)
                Adapted from https://wiki.postgresql.org/wiki/Using_psycopg2_with_PostgreSQL
        :param query: SQL string containing query to execute.
        :param host: Host address of target PostgreSQL instance
        :param dbname: Database to execute query in
        :param user: Username
        :param passwd: Password
        :param return_results: Boolean indicating whether to return query output,
                               otherwise return True or False based on query success
        """

        # Build connection string & remove excess quotes if given
        conn_string = "host='"+host+"' dbname='"+dbname+"' user='"+user+"' password='"+passwd+"'"
        conn_string = conn_string.replace("=''", "='").replace("'' ", "' ")
        print "Connecting to database\n ->%s" % (conn_string)

        try:
                conn = psycopg2.connect(conn_string)
                cursor = conn.cursor()
                print("Sucessfully connected.")
                cursor.execute(query)

                if return_results:
                        return cursor.fetchall()
                else:
                        return True
        except:
                e = sys.exc_info()[0]
                print(e)
                return False

def getSiteID(sitename, host, dbname, user, passwd):
        """
        Get site_id of given sitename from sites table in BETYdb instance pointed to by host.
        :param sitename: string representing sitename field in sites table
        :param host: Host address of target PostgreSQL instance
        :param dbname: Database to execute query in
        :param user: Username
        :param passwd: Password
        :return: site_id as a string, or 0 if query fails
        """

        query = "select first id from sites where sitename = '"+sitename+"'"
        sql = executeSQL(query, host, dbname, user, passwd, True)

        if sql and type(sql) is list:
                # Return id from first row
                return sql[0][0]
        else:
                return 0

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
                return alt_req.json()['USGS_Elevation_Point_Query_Service']['Elevation_Query']['Elevation']
        else:
                return None

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
        api_key_file = r"C:\Users\mburnet2\Documents\NCSA\TERRAref\GOOGLE_ELEVATION_API_KEY.txt"

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
        srid       = 3857
        site_id    = False
        sitename   = False

        out_file   = False
        run_query  = False
        # BETYdb instance details
        host       = None
        dbname     = 'bety'
        user       = 'USERNAME'
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
                        print(__doc__)
                        sys.exit()
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
                elif opt in ("-u", "--user"):
                        user = arg
                elif opt in ("-p", "--pass"):
                        passwd = arg
        if input_file == None and (lon == None or lat == None):
                print('input file is required if no coordinates provided. -h for help.')
                sys.exit(2)
        if not site_id:
                if not host:
                        print('site_id cannot be queried without BETYdb credentials. using 0 as default.')
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
                l = csv.readline()          # header; we can skip this
                l = csv.readline().rstrip() # first data line
                while l:
                        # Get values from each row of file separated by ',' and append to query
                        coords = l.split(",")
                        lon = coords[0]
                        lat = coords[1]
                        q_line = lon + " " + lat
                        if len(coords) == 2:
                                # No altitude has been provided; attempt to fetch it
                                alt = getUSGSAltitude(lon, lat)
                                if alt == '-1000000':
                                        # These coordinates are outside USGS domestic boundary - Google has global coverage
                                        alt = getGoogleAltitude(lon, lat)
                                if alt:
                                        q_line += " " + str(alt)
                        else:
                                q_line += " " + coords[2]

                        l = csv.readline().rstrip() # next data line
                        query += q_line
                        if l:
                                # Don't include a trailing comma on the final set of coordinates
                                query += ","
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
                if not host:
                        print('hostname missing; query will not be executed. -h for help.')
                        sys.exit(2)   
                executeSQL(query, host, dbname, user, passwd)

if __name__ == "__main__":
        main(sys.argv[1:])

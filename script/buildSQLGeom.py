#!/usr/bin/env python

"""
This module will accept an input text file with (x,y,z) coordinates in a CSV-format list
and generate a SQL string that will add these coordinates as a PostGIS Polygon
to sites.geometry within a BETYdb instance.

Command line usage:
        -h      show help
        -i      input filename
        -e      EPSG reference number, default is 3857
        -s      site_id in BETYdb sites table to associate geometry with
        -o      flag to write resulting SQL to output file, as "<input_filename>_SQL.txt"
        -x      will attempt to execute resulting SQL on db instance defined in next 4 params
        -n      PostgreSQL host address
        -d      Database name, default is 'bety'
        -u      Username
        -p      Password

Example:
        buildSQLGeom.py -i C:/folder/coordinates.csv -e 4326 -s 19000000000 -x -n localhost -d bety -u GUEST -p GUES -o

Sample input file contents:
        LONGITUDE,LATITUDE,ALTITUDE
        -76.116081,42.794448,415
        -76.116679,42.794448,415
        -76.116679,42.79231,415
A header row should be included in the document, although the column names do not matter.
"""

import sys
import getopt
#import psycopg2

def executeSQL(query, host, dbname, user, passwd):
        """
        Execute SQL query on specified host database with given credentials.
                Requires psycopg2: https://pypi.python.org/pypi/psycopg2 (un-comment line 32!)
                Adapted from https://wiki.postgresql.org/wiki/Using_psycopg2_with_PostgreSQL
        :param query: SQL string containg query to execute.
        :param host: Host address of target PostgreSQL instance
        :param dbname: Database to execute query in
        :param user: Username
        :param passwd: Password
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
                
        except Exception as e:
                print(e)

def main(argv):
        # These are default values, will be overwritten by command line parameters if given.
        input_file = None
        epsg       = 3857
        site_id    = 0
        out_file   = False
        run_query = False
        host = None
        dbname = 'bety'
        user = 'USERNAME'
        passwd = 'PASSWORD'

        # Parse command line parameters
        try:
                opts, args = getopt.getopt(argv, "hi:e:s:xn:d:u:p:o", ["input=","output=","epsg=","site=","execute","host=","dbname=", "user=", "pass="])
        except getopt.GetoptError:
                print('buildSQLGeom.py -i <inputfile> -e <epsg> -s <site_id> -x -n <postgres_hostname> -d <dbname> -u <username> -p <password> -o <outputfile> ')
                print('epsg default is 3857')
                print('-o will write query to <input_filename>_SQL.txt')
                print('-x will attempt to execute resulting query')
                print('-n, -d, -u, -p required if -x flag enabled')
                sys.exit(2)
        for opt, arg in opts:
                if opt == '-h':
                        print('buildSQLGeom.py -i <inputfile> -e <epsg> -s <site_id> -x -n <postgres_hostname> -d <dbname> -u <username> -p <password> -o <outputfile> ')
                        print('epsg default is 3857')
                        print('-o will write query to <input_filename>_SQL.txt')
                        print('-x will attempt to execute resulting query')
                        print('-n, -d, -u, -p required if -x flag enabled')
                        sys.exit()
                elif opt in ("-i", "--input"):
                        input_file = arg
                elif opt in ("-o", "--output"):
                        out_file = True
                elif opt in ("-e", "--epsg"):
                        epsg = arg
                elif opt in ("-s", "--site"):
                        site_id = arg
                elif opt in ("-x", "--execute"):
                        run_query = True
                elif opt in ("-n", "--host"):
                        host = arg
                elif opt in ("-d", "--dbname"):
                        dbname = arg
                elif opt in ("-u", "--user"):
                        user = arg
                elif opt in ("-p", "--pass"):
                        passwd = arg
        if input_file == None:
                print('input file is required. -h for help.')
                sys.exit(2)
        if out_file:
                # Use input filename with "_SQL.txt"
                input_ext = input_file[input_file.rfind("."):]
                out_file = input_file.replace(input_ext, "_SQL.txt")

        # Generate query by iterating through input file contents
        query = "UPDATE sites SET geometry = ST_Geomfromtext('POLYGON(("

        csv = open(input_file, 'r')
        l = csv.readline()          # header; we can skip this
        l = csv.readline().rstrip() # first data line
        while l:
                # Get values from each row of file separated by ',' and append to query
                coords = l.split(",")
                q_line = coords[0] + " " + coords[1] + " " + coords[2] + ","
                query += q_line 
                l = csv.readline().rstrip()

        # Finish the end of the query and print to console
        query += "))', "+str(epsg)+") WHERE ID="+str(site_id)
        csv.close()

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

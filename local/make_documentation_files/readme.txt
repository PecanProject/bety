How to Use Script:
First open up the .cpp file and edit the connection to the details specified to your database.
  (mysql_real_connect(conn,"localhost","root","password","INFORMATION_SCHEMA",0,NULL,0)== NULL).
  localhost should be changed to the place hosting the database.
  root should be changed to the user accessing the database.
  password should be the pass word of the user accessing the database.
Second compile your script. g++ querymaketables.cpp `mysql_config --cflags --libs` -o querymaketables
Third run your script ./querymaketables
The files should be generated in the fire of your script. querymaketables will generate information about each table
query.c will make a series on comments on each table. You should run query.c first.


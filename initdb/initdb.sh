#!/bin/sh

# create bety user
psql -h postgres -p 5432 -U postgres -c "CREATE ROLE bety WITH LOGIN CREATEDB NOSUPERUSER NOCREATEROLE PASSWORD
 'bety'"

# load database from dump
pg_restore -c -C -v -h postgres -U postgres -d postgres -F c /db.dump

# print some hints on what to do next
echo ""
echo "To fix the database id to be 77 instead of the default of 99:"
echo "docker-compose run -e LOCAL_SERVER=77 bety fix"
echo ""
echo "To add a user, you can use:"
echo "docker-compose run bety user 'login' 'password' 'full name' 'email' 1 1"

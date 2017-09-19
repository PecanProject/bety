#!/bin/bash

# Wait for Postgres to start
# http://www.onegeek.com.au/articles/waiting-for-dependencies-in-docker-compose
WAIT=0
while ! nc -z postgresql 5432; do
  sleep 1
  WAIT=$(($WAIT + 1))
  if [ "$WAIT" -gt 15 ]; then
    echo "Error: Timeout wating for Postgres to start"
    exit 1
  fi
done

# configure ruby app
/bin/sed -e "/username:/ s/bety$/${OWNER}/" \
         -e "/password:/ s/bety$/${PASSWORD}/" \
         -e "/database:/ s/bety$/${DATABASE}/" \
         /home/bety/docker/database.yml > /home/bety/config/database.yml
/bin/sed -e '/serve_static_assets/ s/false$/true/' \
         -i config/environments/production.rb

# start right job
case $1 in
    "initialize" )
        SERVER=$( echo ${REMOTE_SERVERS} | awk '{print $1}' )
        echo "Create new database, initialized from server ${SERVER}"
        psql -h postgresql -p 5432 -U postgres -c "CREATE ROLE ${OWNER} WITH LOGIN CREATEDB NOSUPERUSER NOCREATEROLE PASSWORD '${PASSWORD}'"
        psql -h postgresql -p 5432 -U postgres -c "CREATE DATABASE ${DATABASE} WITH OWNER ${OWNER}"
        ./load.bety.sh -a "postgres" -d "${DATABASE}" -p "-h postgresql -p 5432" -o ${OWNER} -c -u -g -m ${LOCAL_SERVER} -r ${SERVER}
        ;;
    "sync" )
        echo "Synchronize with servers ${REMOTE_SERVERS}"
        for r in ${REMOTE_SERVERS}; do
            ./load.bety.sh -a "postgres" -d "${DATABASE}" -p "-h postgresql -p 5432" -o ${OWNER} -r ${r}
        done
        ;;
    "dump" )
        echo "Dump data from server ${LOCAL_SERVER}"
        ./dump.bety.sh -d "${DATABASE}" -p "-h postgresql -p 5432 -U postgres" -m ${LOCAL_SERVER} -o dump
        ;;
    "migrate" )
        echo "Migrate databae."
        rake db:migrate SKIP_SCHEMASPY=YES
        ;;
    "server" )
        echo "Start running BETY"
        exec rails s
        ;;
    "help" )
        echo "initialize : create a new database and initialize with data from server 0"
        echo "sync       : synchronize database with remote servers ${REMOTE_SERVERS}"
        echo "dump       : dumps local database"
        echo "migrate    : migrates the database to a new version of bety"
        echo "server     : runs the server"
        echo "help       : this text"
        ;;
    * )
        exec "$@"
esac

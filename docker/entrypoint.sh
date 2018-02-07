#!/bin/bash

function wait_for_postgres() {
    echo "Waiting for postgres"
    # Wait for Postgres to start
    # http://www.onegeek.com.au/articles/waiting-for-dependencies-in-docker-compose
    WAIT=0
    while ! nc -w 1 -z postgres 5432; do
      sleep 1
      WAIT=$(($WAIT + 1))
      echo "Try ${WAIT}"
      if [ "$WAIT" -gt 15 ]; then
        echo "Error: Timeout wating for Postgres to start"
        exit 1
      fi
    done
}

# start right job
case $1 in
    "initialize" )
        wait_for_postgres
        SERVER=$( echo ${REMOTE_SERVERS} | awk '{print $1}' )
        echo "Create new database, initialized from server ${SERVER}"
        psql -h postgres -p 5432 -U postgres -c "CREATE ROLE bety WITH LOGIN CREATEDB NOSUPERUSER NOCREATEROLE PASSWORD 'bety'"
        psql -h postgres -p 5432 -U postgres -c "CREATE DATABASE bety WITH OWNER bety"
        ./load.bety.sh -a "postgres" -d "bety" -p "-h postgres -p 5432" -o bety -c -u -g -m ${LOCAL_SERVER} -r ${SERVER}
        ;;
    "sync" )
        wait_for_postgres
        echo "Synchronize with servers ${REMOTE_SERVERS}"
        for r in ${REMOTE_SERVERS}; do
            echo "Synchronizing with server ${r}"
            ./load.bety.sh -a "postgres" -d "bety" -p "-h postgres -p 5432" -o bety -r ${r}
        done
        ;;
    "dump" )
        wait_for_postgres
        echo "Dump data from server ${LOCAL_SERVER}"
        ./dump.bety.sh -d "bety" -p "-h postgres -p 5432 -U postgres" -m ${LOCAL_SERVER} -o dump
        ;;
    "migrate" )
        wait_for_postgres
        echo "Migrate databae."
        rake db:migrate SKIP_SCHEMASPY=YES
        ;;
    "server" )
        wait_for_postgres
        echo "Start running BETY (rails server)"
        exec rails s
        ;;
    "unicorn" )
        wait_for_postgres
        echo "Start running BETY (unicorn)"
        exec bundle exec unicorn -c config/unicorn.rb
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

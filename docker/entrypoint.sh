#!/bin/bash

# start right job
case $1 in
    "initialize" )
        echo "Create new database, initialized from all data."
        psql -h postgres -p 5432 -U postgres -c "CREATE ROLE bety WITH LOGIN CREATEDB NOSUPERUSER NOCREATEROLE PASSWORD 'bety'"
        psql -h postgres -p 5432 -U postgres -c "CREATE DATABASE bety WITH OWNER bety"
        ./script/load.bety.sh -a "postgres" -d "bety" -p "-h postgres -p 5432" -o bety -c -u -g -m ${LOCAL_SERVER} -r 0 -w https://ebi-forecast.igb.illinois.edu/pecan/dump/all/bety.tar.gz
        ;;
    "sync" )
        echo "Synchronize with servers ${REMOTE_SERVERS}"
        for r in ${REMOTE_SERVERS}; do
            echo "Synchronizing with server ${r}"
            ./script/load.bety.sh -a "postgres" -d "bety" -p "-h postgres -p 5432" -o bety -r ${r}
        done
        ;;
    "dump" )
        echo "Dump data from server ${LOCAL_SERVER}"
        ./script/dump.bety.sh -d "bety" -p "-h postgres -p 5432 -U postgres" -m ${LOCAL_SERVER} -o dump
        ;;
    "migrate" )
        echo "Migrate database."
        rake db:migrate SKIP_SCHEMASPY=YES
        ;;
    "server" )
        echo "Start running BETY (rails server)"
        exec rails s
        ;;
    "unicorn" )
        if [ "$RAILS_RELATIVE_URL_ROOT" != "" ]; then
            echo "Compiling assests."
            bundle exec rake assets:precompile
        fi
        echo "Start running BETY (unicorn)"
        exec bundle exec unicorn -c config/unicorn.rb
        ;;
    "autoserver" )
        echo "Migrate database."
        rake db:migrate SKIP_SCHEMASPY=YES
        if [ "$RAILS_RELATIVE_URL_ROOT" != "" ]; then
            echo "Compiling assests."
            bundle exec rake assets:precompile
        fi
        echo "Start running BETY (unicorn)"
        exec bundle exec unicorn -c config/unicorn.rb
        ;;
    "help" )
        echo "initialize : create a new database and initialize with all data from server 0"
        echo "sync       : synchronize database with remote servers ${REMOTE_SERVERS}"
        echo "dump       : dumps local database"
        echo "migrate    : migrates the database to a new version of bety"
        echo "server     : runs the server (using rails server)"
        echo "unicorn    : runs the server (using unicorn)"
        echo "autoserver : runs the server (using unicorn) after running a migrate"
        echo "help       : this text"
        echo ""
        echo "Default is to run bety using unicorn. no automatic migrations."
        ;;
    * )
        exec "$@"
        ;;
esac

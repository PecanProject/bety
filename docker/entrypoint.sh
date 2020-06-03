#!/bin/bash

# start right job
case $1 in
    "initialize" )
        echo "please use pecan/db image to initialize the database."
        exit -1
        ;;
    "sync" )
        echo "Synchronize with servers ${REMOTE_SERVERS}"
        for r in ${REMOTE_SERVERS}; do
            echo "Synchronizing with server ${r}"
            ./script/load.bety.sh -a "${PGUSER}" -d "${BETYDATABASE}" -o ${BETYUSER} -r ${r}
        done
        ;;
    "fix" )
        echo "Fixing database ID"
        ./script/load.bety.sh -a "${PGUSER}" -d "${BETYDATABASE}" -o ${BETYUSER} -f -m ${LOCAL_SERVER}  -r -1
        ;;
    "dump" )
        echo "Dump data from server ${LOCAL_SERVER}"
        ./script/dump.bety.sh -d "${BETYDATABASE}" -m ${LOCAL_SERVER} -o dump
        ;;
    "migrate" )
        echo "Migrate database."
        rake db:migrate SKIP_SCHEMASPY=YES
        ;;
    "reindex" )
        echo "Reindexing database tables"
        ./script/reindex.bety.sh -d "${BETYDATABASE}" -p "-U ${BETYUSER}" 
        ;;
    "reindex-all" )
        echo "Reindexing entire database"
        ./script/reindex.bety.sh -d "${BETYDATABASE}" -p "-U ${BETYUSER}" -s
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
    "vacuum" )
        echo "Vacuuming database tables"
        ./script/vacuum.bety.sh -d "${BETYDATABASE}" -p "-U ${BETYUSER}" -s
        ;;
    "vacuum-all" )
        echo "Vacuuming entire database (not VACUUM FULL)"
        ./script/vacuum.bety.sh -d "${BETYDATABASE}" -p "-U ${BETYUSER}"
        ;;
    "vacuum-full" )-p "-U ${BETYUSER}"
        echo "Full vacuuming of entire database: VACUUM FULL"
        ./script/vacuum.bety.sh -d "${BETYDATABASE}" -p "-U ${BETYUSER}" -f
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
    "user" )
        shift
        ./script/betyuser.sh "$@"
        ;;
    "help" )
        echo "initialize : create a new database and initialize with all data from server 0"
        echo "sync       : synchronize database with remote servers ${REMOTE_SERVERS}"
        echo "dump       : dumps local database"
        echo "migrate    : migrates the database to a new version of bety"
        echo "reindex    : maintentance: reindex the tables in the database"
        echo "reindex-all: maintentance: reindex all of the database, do this sparingly"
        echo "server     : runs the server (using rails server)"
        echo "unicorn    : runs the server (using unicorn)"
        echo "vacuum     : maintenance: vaccum the tables of the database"
        echo "vacuum-all : maintenance: vaccum the entire database (not VACUUM FULL)"
        echo "vacuum-full: maintenance: full vaccum of the database. Specify rarely, if ever"
        echo "autoserver : runs the server (using unicorn) after running a migrate"
        echo "user       : add a new user to BETY database"
        echo "help       : this text"
        echo ""
        echo "Default is to run bety using unicorn. no automatic migrations."
        ;;
    * )
        exec "$@"
        ;;
esac

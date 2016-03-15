#!/bin/bash

if [ "$1" = 'bety' ]; then
    # Add relevant host/port info to database config
    cd /home/bety/config
    /bin/sed -i "/host:/ s/$/ $PG_PORT_5432_TCP_ADDR/" database.yml
    /bin/sed -i "/port:/ s/$/ $PG_PORT_5432_TCP_PORT/" database.yml

    # Create bety database
    # TODO: ping bety database to see if exists, if not load it, otherwise dont overwrite
    createdb -h $PG_PORT_5432_TCP_ADDR -U postgres bety

    # Download & initialize config file
    cd ../script
    ./update-betydb.sh
    ./update-betydb.sh -i
    # Run database install script
    ./update-betydb.sh -o postgres -p "--host=$PG_PORT_5432_TCP_ADDR"

    # psql -h $PG_PORT_5432_TCP_ADDR -p $PG_PORT_5432_TCP_PORT

    cd ..
    rails s
else
    exec "$@"
fi



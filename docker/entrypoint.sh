#!/bin/bash

if [ "$1" = 'bety' ]; then
    # Wait for Postgres to start
    # http://www.onegeek.com.au/articles/waiting-for-dependencies-in-docker-compose
    WAIT=0
    while ! nc -z $PG_PORT_5432_TCP_ADDR $PG_PORT_5432_TCP_PORT; do
      sleep 1
      WAIT=$(($WAIT + 1))
      if [ "$WAIT" -gt 15 ]; then
        echo "Error: Timeout wating for Postgres to start"
        exit 1
      fi
    done

    # Move database config file into config directory & add host/port
    cd /home/bety/config
    /bin/cp /home/bety/docker/database.yml database.yml
    /bin/sed -i "/host:/ s/$/ $PG_PORT_5432_TCP_ADDR/" database.yml
    /bin/sed -i "/port:/ s/$/ $PG_PORT_5432_TCP_PORT/" database.yml

    # Create bety database if it does not exist
    if ! psql -h $PG_PORT_5432_TCP_ADDR -p $PG_PORT_5432_TCP_PORT -U postgres -lqt | cut -d \| -f 1 | grep -w "bety" > /dev/null ; then
      echo "Creating bety database"
      createdb -U postgres -h $PG_PORT_5432_TCP_ADDR -p $PG_PORT_5432_TCP_PORT bety
    fi

    # Download & initialize Bety database contents
    cd ../script
    curl -LOs https://raw.githubusercontent.com/PecanProject/pecan/master/scripts/load.bety.sh
    chmod +x load.bety.sh
    ./load.bety.sh -a "postgres" -p "-h $PG_PORT_5432_TCP_ADDR -p $PG_PORT_5432_TCP_PORT" -o postgres -c -u -g -r 0 -m 99

    cd ..
    rake db:migrate
    rails s
else
    exec "$@"
fi

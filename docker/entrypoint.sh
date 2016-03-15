#!/bin/bash

if [ "$1" = 'bety' ]; then

    BETY_VERSION="betydb_4.5"

    # Download BETY zip file from pecan archive
    cd /home/bety
    #curl -LOk https://github.com/PecanProject/bety/archive/${BETY_VERSION}.zip
    #unzip ${BETY_VERSION}.zip
    #cd bety-${BETY_VERSION}

    # Comment out capybara-webkit line and install Rails dependencies
    #/bin/sed -i "/capybara-webkit/ s/^/# /" Gemfile
    #gem install bundler
    #bundle install

    # Move database config file into config directory
    cd config
    /bin/cp /home/bety/docker/database.yml database.yml
    /bin/sed -i "/host:/ s/$/ $PG_PORT_5432_TCP_ADDR/" database.yml
    /bin/sed -i "/port:/ s/$/ $PG_PORT_5432_TCP_PORT/" database.yml
    # /bin/cp application.yml.template application.yml

    # Create bety database
    createdb -h $PG_PORT_5432_TCP_ADDR bety

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

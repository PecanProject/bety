#!/bin/sh

# sanity checks
echo "----------------------------------------------------------------------"
if [ -z $FORCE ]; then
    echo "Safety checks"
    echo ""
    if [ "$BETYUSER" != "bety" ]; then
        psql -d postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='bety'" | grep -q 1 && \
            echo "User bety already exists, please remove user first." && exit 0
    fi
    psql -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='bety'" | grep -q 1 && \
        echo "Database bety already exists, please remove database first." && exit 0
    psql -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='${BETYDATABASE}'" | grep -q 1 && \
        echo "Database ${BETYDATABASE} already exists, please remove database first." && exit 0
else
    echo "Forced deletion of database and user."
    echo ""
    psql -c "DROP DATABASE IF EXISTS bety;"
    psql -c "DROP DATABASE IF EXISTS ${BETYDATABASE};"
    psql -c "DROP ROLE IF EXISTS bety;"
fi
echo "----------------------------------------------------------------------"

# create bety user for restoring database
echo ""
echo "----------------------------------------------------------------------"
if [ "$BETYUSER" != "bety" ]; then
    echo "Create user 'bety' exists for restore, this user is removed at the end."
else
    echo "Making sure user 'bety' exists."
fi
echo ""
psql -d postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='bety'" | grep -q 1 || \
    psql -c "CREATE ROLE bety WITH LOGIN CREATEDB NOSUPERUSER NOCREATEROLE PASSWORD '${BETYPASSWORD}';"
echo "----------------------------------------------------------------------"

# load database from dump
echo ""
echo "----------------------------------------------------------------------"
echo "Restoring database, this will take some time."
echo "There might be a few errors (last check 5) that can be safely ignored."
echo ""
pg_restore --clean --verbose --create --if-exists --format c --dbname postgres /db.dump
echo "----------------------------------------------------------------------"

# rename database
if [ "$BETYDATABASE" != "bety" ]; then
    echo ""
    echo "----------------------------------------------------------------------"
    echo "Changing database name to ${BETYDATABASE}"
    echo ""
    psql -c "ALTER DATABASE \"bety\" RENAME TO \"${BETYDATABASE}\";"
    echo "----------------------------------------------------------------------"
fi

# change ownership of database
if [ "$BETYUSER" != "bety" ]; then
    echo ""
    echo "----------------------------------------------------------------------"
    echo "Changing database ownership to ${BETYUSER}"
    echo ""
    psql -d postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='${BETYUSER}'" | grep -q 1 || \
        psql -c "CREATE ROLE ${BETYUSER} WITH LOGIN CREATEDB NOSUPERUSER NOCREATEROLE PASSWORD '${BETYPASSWORD}';"
    psql -d ${BETYDATABASE} -c "REASSIGN OWNED BY bety TO ${BETYUSER};"
    psql -c "DROP ROLE IF EXISTS bety;"
    echo "----------------------------------------------------------------------"
fi

# print some hints on what to do next
echo ""
echo "----------------------------------------------------------------------"
echo ""
echo "To fix the database id to be 77 instead of the default of 99:"
echo "docker-compose run -e LOCAL_SERVER=77 bety fix"
echo ""
echo "To add a user, you can use:"
echo "docker-compose run bety user 'login' 'password' 'full name' 'email' 1 1"
echo "----------------------------------------------------------------------"

#!/bin/sh

# create bety user
psql -h postgres -p 5432 -U postgres -c "CREATE ROLE bety WITH LOGIN CREATEDB NOSUPERUSER NOCREATEROLE PASSWORD
 'bety'"

# load database from dump
pg_restore -c -C -v -h postgres -U postgres -d postgres -F c /db.dump

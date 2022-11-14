#!/bin/bash

# exit on error
set -e

# ----------------------------------------------------------------------
# START CONFIGURATION SECTION
# ----------------------------------------------------------------------

# name of the dabase to load
# this script assumes the user running it has access to the database
DATABASE=${DATABASE:-"bety"}

# owner of the database
# also used to connect to the database for most operations
OWNER=${OWNER:-"bety"}

# postgres user to use for root level access
PG_USER=${PG_USER:-""}

# psql options
# this allows you to add any other options
PG_OPT=${PG_OPT:-""}

# ID's used in database
# These ID's need to be unique for the sharing to work. If you want
# to share your data, send email to kooper@illinois.edu to claim
# your ID range. The master list is maintained at
# https://github.com/PecanProject/betydb-documentation/blob/master/betydb-system-administration/distributed_betydb.md
#
#  0 - EBI                   - David Slater
#  1 - BU                    - Mike Dietze
#  2 - Brookhaven            - Shawn Serbin
#  3 - Purdue                - Jeanne Osnas
#  4 - Virginia Tech         - Quinn Thomas
#  5 - Wisconsin             - Ankur Desai
#  6 - TERRA REF             - David LeBauer
#  7 - TERRA test            - David LeBauer
#  8 - TERRA MEPP            - David Slater
#  9 - University of Arizona - David LeBauer
# 10 - Ghent                 - 
# 99 - VM
MYSITE=${MYSITE:-99}
REMOTESITE=${REMOTESITE:-0}
DUMPURL=${DUMPURL:-""}

# Create the database from scratch
# Set this to YES to create the database, this will remove all existing
# data!
CREATE=${CREATE:-"NO"}

# Empty database create
# Set this to YES to create an empty database, this will still
# import some rows, such as mimetypes, etc.
EMPTY=${EMPTY:-"NO"}

# Fix the sequence numbers, this should only be need when creating a
# new database. Set this to YES to initialize the sequence numbers.
FIXSEQUENCE=${FIXSEQUENCE:-"NO"}

# Keep the tmp folder even if the sync failed?
# Set this to YES to keep the tmp folder, this is helpful for
# debugging the script. The default value is NO and the tmp folder will
# be removed
KEEPTMP=${KEEPTMP:-"NO"}

# Should the process be quiet
QUIET=${QUIET:-"NO"}

# Add some default users
# Set this to YES to add carya with password. This will give this user
# admin priviliges. It will also create 16 more users that have specific
# abilities.
USERS=${USERS:-"NO"}

# create guestuser
# Set this to YES to create guestuser used with BETY.
GUESTUSER=${GUESTUSER:-"NO"}

# additional options for curl
CURL_OPTS=${CURL_OPTS:-""}

# additional options for splitting large files
# Maximum size before splitting
SPLIT_FILE_MAX=${SPLIT_FILE_MAX:-200000}
# Size of split files
SPLIT_FILE_SIZE=${SPLIT_FILE_SIZE:-10000}

# Log file
LOG=${LOG:-"$PWD/dump/sync.log"}

# ----------------------------------------------------------------------
# END CONFIGURATION SECTION
# ----------------------------------------------------------------------

# parse command line options
while getopts a:cd:efghkl:m:o:p:qr:tuw: opt; do
  case $opt in
  a)
    PG_USER="$OPTARG"
    ;;
  b)
    SPLIT_FILE_MAX="$OPTARG"
    ;;
  c)
    CREATE="YES"
    ;;
  d)
    DATABASE="$OPTARG"
    ;;
  e)
    EMPTY="YES"
    ;;
  f)
    FIXSEQUENCE="YES"
    ;;
  g)
    GUESTUSER="YES"
    ;;
  h)
    echo "$0 [-a postgres] [-b split max] [-c] [-d database] [-e] [-f] [-g] [-h] [-l logfile] [-m my siteid] [-o owner] [-p psql options] [-r remote siteid] [-s split size] [-t] [-u]"
    echo " -a access database as this user, this is NOT the owner of the database, often this is postgres"
    echo " -b maximum input lines before input file is split, default $SPLIT_FILE_MAX lines (see -s)"
    echo " -c create database, THIS WILL ERASE THE CURRENT DATABASE, default is NO"
    echo " -d database, default is bety"
    echo " -e empty database, default is NO"
    echo " -f fix sequence numbers, this should not be needed, default is NO"
    echo " -g add guestuser for BETY webpage"
    echo " -h this help page"
    echo " -k allow for insecure connections when downloading data"
    echo " -l location of log file (place this with the dump files)"
    echo " -m site id, default is 99 (VM)"
    echo " -o owner of the database, default is bety"
    echo " -p additional psql command line options, default is empty"
    echo " -q should the import be quiet"
    echo " -r remote site id, default is 0 (EBI)"
    echo " -s split lines per file, default $SPLIT_FILE_SIZE lines (when splitting input files) (see -b)"
    echo " -t keep temp folder, default is NO"
    echo " -u create carya users, this will create some default users"
    echo " -w use url to fetch data from instead of hardcoded url"
    exit 0
    ;;
  k)
    CURL_OPTS="${CURL_OPTS} --insecure"
    ;;
  l)
    LOG="$OPTARG"
    ;;
  m)
    MYSITE="$OPTARG"
    ;;
  o)
    OWNER="$OPTARG"
    ;;
  p)
    PG_OPT="$OPTARG"
    ;;
  q)
    QUIET="YES"
    ;;
  r)
    REMOTESITE="$OPTARG"
    ;;
  s)
    SPLIT_FILE_SIZE="$OPTARG"
    ;;
  t)
    KEEPTMP="YES"
    ;;
  u)
    USERS="YES"
    ;;
  w)
    DUMPURL="$OPTARG"
    ;;
  esac
done

# simple sanity check
if [ "${CREATE}" == "YES" -a "${OWNER}" == "" ]; then
  echo "Can not create database without owner"
  exit 1
fi
if [ "${MYSITE}" == "${REMOTESITE}" ]; then
  echo "Can not have same remotesite as mysite"
  exit 1
fi
if [ "${CREATE}" == "YES" ]; then
  FIXSEQUENCE="YES"
fi

# add right flag to PG_USER
if [ "$PG_USER" != "" ]; then
  PG_USER="-U ${PG_USER}"
fi
if [ "$OWNER" != "" ]; then
  PG_OWNER="-U ${OWNER}"
fi

# this seems to be a good option always
PG_OPT="${PG_OPT} -v ON_ERROR_ROLLBACK=on"

# this value should be constant, do not change
ID_RANGE=1000000000

# list of all tables, schema_migrations is ignored since that
# will be imported during creaton

# list of tables that are part of an empty setup
EMPTY_TABLES="formats machines mimetypes users"

# list of all tables, schema_migrations is ignored since that
# will be imported during creaton. Order is semi important.
CLEAN_TABLES="attributes benchmark_sets benchmarks"
CLEAN_TABLES="${CLEAN_TABLES} citations covariates cultivars"
CLEAN_TABLES="${CLEAN_TABLES} ensembles entities experiments inputs"
CLEAN_TABLES="${CLEAN_TABLES} likelihoods managements metrics"
CLEAN_TABLES="${CLEAN_TABLES} methods models modeltypes"
CLEAN_TABLES="${CLEAN_TABLES} pfts posteriors priors reference_runs"
CLEAN_TABLES="${CLEAN_TABLES} runs sites species treatments"
CLEAN_TABLES="${CLEAN_TABLES} variables workflows"
CLEAN_TABLES="${CLEAN_TABLES} projects sitegroups"
CLEAN_TABLES="${CLEAN_TABLES} dbfiles"

# tables that have checks that need to be looked at.
CHECK_TABLES="traits yields"

# tables that have many to many relationships
MANY_TABLES="benchmarks_benchmarks_reference_runs benchmarks_ensembles"
MANY_TABLES="${MANY_TABLES} benchmarks_ensembles_scores benchmarks_metrics benchmark_sets_benchmark_reference_runs"
MANY_TABLES="${MANY_TABLES} citations_sites citations_treatments"
MANY_TABLES="${MANY_TABLES} cultivars_pfts current_posteriors"
MANY_TABLES="${MANY_TABLES} experiments_sites experiments_treatments"
MANY_TABLES="${MANY_TABLES} formats_variables inputs_runs"
MANY_TABLES="${MANY_TABLES} managements_treatments modeltypes_formats"
MANY_TABLES="${MANY_TABLES} pfts_priors pfts_species"
MANY_TABLES="${MANY_TABLES} posterior_samples posteriors_ensembles"
MANY_TABLES="${MANY_TABLES} sitegroups_sites sites_cultivars trait_covariate_associations"

# tables that should NOT be dumped
IGNORE_TABLES="sessions"
SYSTEM_TABLES="schema_migrations spatial_ref_sys"

# before anything is done, check to make sure database exists
if ! psql ${PG_OPT} ${PG_USER} -lqt | cut -d \| -f 1 | grep -w "^ *${DATABASE} *$" > /dev/null ; then
  echo "Database ${DATABASE} does not exist, please create it:"
  echo "(see https://pecanproject.github.io/bety-documentation/technical/deploying-a-production-copy-of-the-betydb-web-application.html)"
  echo "  psql ${PG_OPT} ${PG_USER} -c \"CREATE ROLE ${OWNER} WITH LOGIN CREATEDB NOSUPERUSER NOCREATEROLE PASSWORD 'password'\""
  echo "  psql ${PG_OPT} ${PG_USER} -c \"CREATE DATABASE ${DATABASE} WITH OWNER ${OWNER}\""
  exit 1
fi

# check the database for information first
if [ -z "${DUMPURL}" ]; then
  DUMPURL=$(psql ${PG_OPT} ${PG_USER} -q -d "${DATABASE}" -t -c "SELECT sync_url FROM machines WHERE sync_host_id = ${REMOTESITE};" 2>/dev/null | xargs )
fi
if [ -z "${DUMPURL}" ]; then
  if [ "${FIXSEQUENCE}" != "YES" -o "${CREATE}" == "YES" ]; then
    echo "Did not find a sync_url in database, please update database, or provide script with DUMPURL."
    exit -1
  fi
fi

MY_START_ID=$(psql ${PG_OPT} ${PG_USER} -q -d "${DATABASE}" -t -c "SELECT sync_start FROM machines WHERE sync_host_id = ${MYSITE};" 2>/dev/null | xargs )
if [ -z "${MY_START_ID}" ]; then
  MY_START_ID=$(( MYSITE * ID_RANGE + 1 ))
fi
MY_LAST_ID=$(psql ${PG_OPT} ${PG_USER} -q -d "${DATABASE}" -t -c "SELECT sync_end FROM machines WHERE sync_host_id = ${MYSITE};" 2>/dev/null | xargs )
if [ -z "${MY_LAST_ID}" ]; then
  MY_LAST_ID=$(( MY_START_ID + ID_RANGE - 2 ))
fi

REM_START_ID=$(psql ${PG_OPT} ${PG_USER} -q -d "${DATABASE}" -t -c "SELECT sync_start FROM machines WHERE sync_host_id = ${REMOTESITE};" 2>/dev/null | xargs )
if [ -z "${REM_START_ID}" ]; then
  REM_START_ID=$(( REMOTESITE * ID_RANGE + 1 ))
fi
REM_LAST_ID=$(psql ${PG_OPT} ${PG_USER} -q -d "${DATABASE}" -t -c "SELECT sync_end FROM machines WHERE sync_host_id = ${REMOTESITE};" 2>/dev/null | xargs )
if [ -z "${REM_LAST_ID}" ]; then
  REM_LAST_ID=$(( REM_START_ID + ID_RANGE - 2 ))
fi

if [ "${QUIET}" != "YES" ]; then
  printf "URL with bety dump                 : ${DUMPURL}\n"
  printf "Remote start ID                    : %11d\n" "${REM_START_ID}"
  printf "Remote end ID                      : %11d\n" "${REM_LAST_ID}"
  printf "Local start ID                     : %11d\n" "${MY_START_ID}"
  printf "Local end ID                       : %11d\n" "${MY_LAST_ID}"
fi

# make output folder
DUMPDIR="/tmp/$$"
mkdir "${DUMPDIR}"

# cleanup
trap '
  rm -rf ${DUMPDIR}
' EXIT

# download dump file and unpack
if [ "${DUMPURL}" != "" ]; then
  curl ${CURL_OPTS} -s -L -o "${DUMPDIR}/dump.tar.gz" "${DUMPURL}"
  if [ ! -s ${DUMPDIR}/dump.tar.gz ]; then
    echo "File downloaded is 0 bytes"
    exit 1
  else
    tar zxf "${DUMPDIR}/dump.tar.gz" -C "${DUMPDIR}" -m
  fi
fi

# create database if need be, otherwise check version of schema
if [ "${DUMPURL}" != "" ]; then
  if [ "${CREATE}" == "YES" ]; then
    if [ "${QUIET}" != "YES" ]; then
       printf "Loading %-25s : " "schema"
    fi

    # create empty public schema
    psql ${PG_OPT} ${PG_USER} -q -d "${DATABASE}" -c "DROP SCHEMA public CASCADE;"
    psql ${PG_OPT} ${PG_USER} -q -d "${DATABASE}" -c "CREATE SCHEMA public AUTHORIZATION ${OWNER};"
    psql ${PG_OPT} ${PG_USER} -q -d "${DATABASE}" -c "CREATE EXTENSION postgis;"
    psql ${PG_OPT} ${PG_USER} -q -d "${DATABASE}" -c "GRANT ALL ON ALL TABLES IN SCHEMA public TO ${OWNER};"

    # load the schema
    psql ${PG_OPT} -U ${OWNER} -q -d "${DATABASE}" < "${DUMPDIR}"/*.schema
    if [ "${QUIET}" != "YES" ]; then
      echo "CREATED SCHEMA"
    fi

    if [ "${QUIET}" != "YES" ]; then
      printf "Loading  %-25s : " "schema_migrations"
    fi
    ADD=$( psql ${PG_OPT} ${PG_OWNER} -t -q -d "${DATABASE}" -c "\COPY schema_migrations FROM '${DUMPDIR}/schema_migrations.csv' WITH (DELIMITER '	',  NULL '\\N', ESCAPE '\\', FORMAT CSV, ENCODING 'UTF-8'); SELECT COUNT(*) FROM schema_migrations;" | tr -d ' ' )
    if [ "${QUIET}" != "YES" ]; then
      echo "ADDED ${ADD}"
    fi
  else
    if [ "${QUIET}" != "YES" ]; then
      printf "Checking %-25s : " "schema"
    fi

    # find current schema version
    VERSION=$( psql ${PG_OPT} ${PG_OWNER} -t -q -d "${DATABASE}" -c 'SELECT md5(array_agg(version)::text) FROM (SELECT version FROM schema_migrations ORDER BY version) as v;' | tr -d ' ' )

    if [ ! -e "${DUMPDIR}/${VERSION}.schema" ]; then
      echo "EXPECTED SCHEMA version ${VERSION}"
      echo "Dump is from a different schema, please fix schema in database."
      if [ "$KEEPTMP" == "YES" ]; then
        echo "Files are in ${DUMPDIR}"
      else
        rm -rf "${DUMPDIR}"
      fi
      if [ -e ${LOG} ]; then
        echo `date -u` $REMOTESITE 1 >> $LOG
      fi
      exit 1
    fi

    if [ "${QUIET}" != "YES" ]; then
      echo "MATCHED SCHEMA version ${VERSION}"
    fi
  fi
fi

# common statement pieces used
REM_WHERE="WHERE (id >= ${REM_START_ID} AND id <= ${REM_LAST_ID})"
MY_WHERE="WHERE (id >= ${MY_START_ID} AND id <= ${MY_LAST_ID})"

# disable all triggers 
for T in ${EMPTY_TABLES} ${CLEAN_TABLES} ${MANY_TABLES}; do
  psql ${PG_OPT} ${PG_USER} -q -d "${DATABASE}" -c "ALTER TABLE ${T} DISABLE TRIGGER ALL;"
done

# create psql process that will be used for all code
PSQL_PIPE_INP=/tmp/psql_inp.$$
PSQL_PIPE_OUT=/tmp/psql_out.$$
mkfifo -m 600 $PSQL_PIPE_INP
mkfifo -m 600 $PSQL_PIPE_OUT
psql ${PG_OPT} ${PG_USER} -q --no-align --no-readline --tuples-only -P footer=off -d ${DATABASE} <$PSQL_PIPE_INP >$PSQL_PIPE_OUT &
exec 3>$PSQL_PIPE_INP
exec 4<$PSQL_PIPE_OUT
PSQL_PID=$!
if [ "${QUIET}" != "YES" ]; then
  echo "Started psql (pid=$PSQL_PID)"
fi

# capture EXIT so we can rollback if needed, as well as cleanup
trap '
  if ps -p $PSQL_PID > /dev/null ; then
    echo "Process killed, no changes are made to the database."
    echo "ROLLBACK;" >&3
    kill $PSQL_PID
    cat <&4
    if [ -e ${LOG} ]; then
      echo `date -u` $REMOTESITE 2 >> $LOG
    fi
  fi
  rm -f $PSQL_PIPE_INP $PSQL_PIPE_OUT
' EXIT

# start transaction

# for all tables
# 1) disable constraints on this table
# 2) remove all rows that have id in range of remote site
# 3) load new data
# 4) set last inserted item in my range
# 5) enable constraints on this table
PREV_SPLIT=""
for T in ${EMPTY_TABLES} ${CLEAN_TABLES} ${CHECK_TABLES} ${MANY_TABLES}; do
  # Start
  if [ "${PREV_SPLIT}" != "" ]; then
    if [ "${QUIET}" != "YES" ]; then
      echo "Cleaning up previous split: ${PREV_SPLIT}"
    fi
    rm ${DUMPDIR}/${PREV_SPLIT}????.csv
    PREV_SPLIT=""
  fi

  # start upload process
  echo "BEGIN;" >&3
  echo "ALTER TABLE ${T} DISABLE TRIGGER ALL;" >&3

  if [ "${DUMPURL}" != "" ]; then
    echo "SELECT count(*) FROM ${T} ${REM_WHERE};" >&3 && read DEL <&4
    # TODO what is last index in range we are adding, this will give a better
    #      indication if rows are added.
    echo "DELETE FROM ${T} ${REM_WHERE};" >&3
    echo "SELECT COUNT(*) FROM ${T};" >&3 && read START <&4
    if [[ "${EMPTY}" == "NO" || ${EMPTY_TABLES} == *"$T"* ]]; then
      if [ -f "${DUMPDIR}/${T}.csv" ]; then
	T_SIZE=`cat ${DUMPDIR}/${T}.csv | wc -l`
	if [ "${T_SIZE}" -gt "${SPLIT_FILE_MAX}" ]; then
	  if [ "${QUIET}" != "YES" ]; then
	    echo "splitting input ${DUMPDIR}/${T}.csv - ${T_SIZE} lines (${SPLIT_FILE_MAX} limit, ${SPLIT_FILE_SIZE} split lines)"
	  fi
	  PREV_SPLIT="${T}"
	  RES=`pushd ${DUMPDIR} && split -d -a 4 --additional-suffix=.csv -l ${SPLIT_FILE_SIZE} ${DUMPDIR}/${T}.csv ${T} && popd`
	  IDX=0
	  FOUND=true
	  while [ "${FOUND}" = true ]; do
	    SPLIT_FILE=`VAL=${IDX} ; printf -v VAL "${DUMPDIR}/${T}%04d.csv" $VAL; echo ${VAL}`
	    if [ -e "${SPLIT_FILE}" ]; then
              echo "\COPY ${T} FROM '${SPLIT_FILE}' WITH (DELIMITER '	',  NULL '\\N', ESCAPE '\\', FORMAT CSV, ENCODING 'UTF-8')" >&3
	    else
	      FOUND=false
	    fi
	    IDX=$((IDX+1))
	  done
	else
          echo "\COPY ${T} FROM '${DUMPDIR}/${T}.csv' WITH (DELIMITER '	',  NULL '\\N', ESCAPE '\\', FORMAT CSV, ENCODING 'UTF-8')" >&3
	fi
      fi
    fi
    echo "SELECT COUNT(*) FROM ${T};" >&3 && read END <&4
    ADD=$(( END - START ))
    DIFF=$(( ADD - DEL ))
    if [ "${QUIET}" != "YES" ]; then
      if [ "$DEL" != "0" -o "$ADD" != "0" ]; then
        if [ "$DIFF" != "0" ]; then
          printf "Updated  %-25s : %11d (%+d)\n" "${T}" ${ADD} ${DIFF}
        else
          printf "Updated  %-25s : %11d\n" "${T}" ${ADD}
        fi
      fi
    fi
  fi
  
  # fix sequence number
  if [ "${FIXSEQUENCE}" == "YES" ]; then
    echo "SELECT last_value from ${T}_id_seq;" >&3 && read OLD <&4
    echo "SELECT setval('${T}_id_seq', ${MY_START_ID}, false);" >&3 && read IGN <&4
    echo "SELECT setval('${T}_id_seq', (SELECT MAX(id) FROM ${T} ${MY_WHERE}), true);" >&3 && read IGN <&4
    echo "SELECT last_value from ${T}_id_seq;" >&3 && read NEXT <&4
    if [ "${QUIET}" != "YES" ]; then
      if [ "$OLD" != "$NEXT" ]; then
        printf "Fixed    %-25s : %s\n" "${T}" "${NEXT}"
      fi
    fi
  fi

  # finish off
  echo "ALTER TABLE ${T} ENABLE TRIGGER ALL;" >&3
  echo "END;" >&3
done

# fix sequence numbers if needed
if [ "${FIXSEQUENCE}" == "YES" ]; then
  for T in ${IGNORE_TABLES}; do
    echo "SELECT last_value from ${T}_id_seq;" >&3 && read OLD <&4
    echo "SELECT setval('${T}_id_seq', ${MY_START_ID}, false);" >&3 && read IGN <&4
    echo "SELECT setval('${T}_id_seq', (SELECT MAX(id) FROM ${T} ${MY_WHERE}), true);" >&3 && read IGN <&4
    echo "SELECT last_value from ${T}_id_seq;" >&3 && read NEXT <&4
    if [ "${QUIET}" != "YES" ]; then
      if [ "$OLD" != "$NEXT" ]; then
        printf "Fixed    %-25s : %s\n" "${T}" "${NEXT}"
      fi
    fi
  done
fi

# Add carya and other users if requested.
if [ "${USERS}" == "YES" ]; then

  # add carya user with admin rights
  echo "SELECT count(id) FROM users WHERE login='carya';" >&3 && read RESULT <&4
  if [ ${RESULT} -eq 0 ]; then
    echo "SELECT nextval('users_id_seq');" >&3 && read ID <&4
    $(dirname $0)/betyuser.sh "carya" "illinois" "carya" "betydb+${ID}@gmail.com" 1 1
    if [ "${QUIET}" != "YES" ]; then
      echo "Added carya with admin privileges with id=${ID}"
    fi
  fi
fi

# Add guest user
if [ "${GUESTUSER}" == "YES" ]; then
  # add guest user
  echo "SELECT count(id) FROM users WHERE login='guestuser';" >&3 && read RESULT <&4
  if [ ${RESULT} -eq 0 ]; then
    echo "SELECT nextval('users_id_seq');" >&3 && read ID <&4
    $(dirname $0)/betyuser.sh "guestuser" "guestuser" "guestuser" "betydb+${ID}@gmail.com" 4 4
    if [ "${QUIET}" != "YES" ]; then
      echo "Added guestuser with access_level=4 and page_access_level=4 with id=${ID}"
    fi
  fi
fi

# close transaction
if [ -e ${LOG} ]; then
  echo `date -u` $REMOTESITE 0 >> $LOG
fi
echo "\quit" >&3
wait $PSQL_PID

# all done, cleanup
rm -rf "${DUMPDIR}"

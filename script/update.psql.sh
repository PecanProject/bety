#!/bin/bash

set -x

# ----------------------------------------------------------------------
# START CONFIGURATION SECTION
# ----------------------------------------------------------------------

# name of the dabase to load
# this script assumes the user running it has access to the database
DATABASE=${DATABASE:-"bety"}

# owner of the database
# also used to connect to the database for most operations
OWNER=${OWNER:-"bety"}

# Keep the dump file even if the update failed?
# Set this to YES to keep the update file; this is helpful for debugging the
# script. The default value is NO and the update file will be removed.
# TODO: Make this work!
KEEPTMP=${KEEPTMP:-"NO"}

# If this is set to YES, one user will be converted to carya with password. This
# will give this user admin priviliges. It will also create 16 more users that
# have specific abilities and create the guest user.  Set USERS to NO to skip
# these steps.
USERS=${USERS:-YES}
 
# ----------------------------------------------------------------------
# END CONFIGURATION SECTION
# ----------------------------------------------------------------------


# command to connect to database
if [ "`uname -s`" != "Darwin" ]; then
  export POSTGRES="sudo -u postgres"
fi
export CMD="${POSTGRES} psql -U ${OWNER}"

# load latest dump of the database
curl -o betydump.gz https://ebi-forecast.igb.illinois.edu/pecan/dump/betydump.psql.gz

${POSTGRES} dropdb ${DATABASE}
${POSTGRES} createdb -O ${OWNER} ${DATABASE}

gunzip -c betydump.gz | ${CMD} -d ${DATABASE}
rm betydump.gz

if [ "${USERS:-YES}" == "YES" ]; then
  ID=2

  RESULT=$( ${POSTGRES} psql -t -d "${DATABASE}" -c "SELECT count(id) FROM users WHERE login='carya';" )
  if [ ${RESULT} -eq 0 ]; then
    RESULT='UPDATE 0'
    while [ "${RESULT}" = "UPDATE 0" ]; do
      RESULT=$( ${POSTGRES} psql -t -d "${DATABASE}" -c "UPDATE users SET login='carya', name='carya', crypted_password='df8428063fb28d75841d719e3447c3f416860bb7', salt='carya', access_level=1, page_access_level=1 WHERE id=${ID};" )
      ((ID++))
    done
  fi
  echo "Added carya with admin privileges"

  # set all users
  for f in 1 2 3 4; do
    for g in 1 2 3 4; do
      RESULT=$( ${POSTGRES} psql -t -d "${DATABASE}" -c "SELECT count(id) FROM users WHERE login='carya${f}${g}';" )
      if [ ${RESULT} -eq 0 ]; then
        RESULT='UPDATE 0'
        while [ "${RESULT}" = "UPDATE 0" ]; do
          RESULT=$( ${POSTGRES} psql -t -d "${DATABASE}" -c "UPDATE users SET login='carya${f}${g}', name='carya a-${f} p-${g}', crypted_password='df8428063fb28d75841d719e3447c3f416860bb7', salt='carya', access_level=${f}, page_access_level=${g} WHERE id=${ID};" )
          ((ID++))
        done
      fi
    done
  done
  echo "Updated users to have login='caryaXY' with appropriate privileges"
  echo "  (X=access_level, Y=page_access_level)."

  # add guest user
  RESULT=$( ${POSTGRES} psql -t -d "${DATABASE}" -c "SELECT count(id) FROM users WHERE login='guestuser';" )
  if [ ${RESULT} -eq 0 ]; then
    RESULT='UPDATE 0'
    while [ "${RESULT}" = "UPDATE 0" ]; do
      RESULT=$( ${POSTGRES} psql -t -d "${DATABASE}" -c "UPDATE users SET login='guestuser', name='guestuser', crypted_password='994363a949b6486fc7ea54bf40335127f5413318', salt='bety', access_level=4, page_access_level=4 WHERE id=${ID};" )
      ((ID++))
    done
  fi
  echo "Added guestuser with access_level=4 and page_access_level=4"
fi

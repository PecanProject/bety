#!/bin/bash

set -x

# command to connect to database
if [ "`uname -s`" != "Darwin" ]; then
  export POSTGRES="sudo -u postgres"
fi
export CMD="${POSTGRES} psql -U bety"

# load latest dump of the database
curl -o betydump.gz https://ebi-forecast.igb.illinois.edu/pecan/dump/betydump.psql.gz

${POSTGRES} dropdb bety
${POSTGRES} createdb -O bety bety

gunzip -c betydump.gz | ${CMD} bety
rm betydump.gz

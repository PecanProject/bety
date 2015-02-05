#!/bin/bash

DATABASE=${DATABASE:-"bety"}
OWNER=${OWNER:-"bety"}
PG_OPT=${PG_OPT:-""}
MYSITE=${MYSITE:-99}

# list of tables that are many to many relationships
MANY_TABLES="${MANY_TABLES} citations_sites citations_treatments"
MANY_TABLES="${MANY_TABLES} formats_variables inputs_runs"
MANY_TABLES="${MANY_TABLES} inputs_variables"
MANY_TABLES="${MANY_TABLES} managements_treatments pfts_priors"
MANY_TABLES="${MANY_TABLES} pfts_species posteriors_ensembles"

ID_RANGE=1000000000
START_ID=$(( MYSITE * ID_RANGE + 1 ))
LAST_ID=$(( START_ID + ID_RANGE - 1 ))

for T in ${MANY_TABLES}; do
  Z=(${T//_/ })
  X=${Z[0]}
  X=${X%s}
  Y=${Z[1]}
  Y=${Y%s}
  printf "Fixing %-25s : " "${T}"
  psql -q -d "${DATABASE}" -c "ALTER TABLE ${T} DISABLE TRIGGER ALL;"
  WHERE="WHERE (${X}_id >= ${START_ID} AND ${X}_id <= ${LAST_ID}) OR (${Y}_id >= ${START_ID} AND ${Y}_id <= ${LAST_ID})"
  FIX=$( psql ${PG_OPT} -U ${OWNER} -t -q -d "${DATABASE}" -c "SELECT count(*) FROM ${T} ${WHERE}" | tr -d ' ' )
  IGN=$( psql ${PG_OPT} -U ${OWNER} -t -q -d "${DATABASE}" -c "SELECT setval('${T}_id_seq', ${START_ID}, false); SELECT setval('${T}_id_seq', (SELECT MAX(id) FROM ${T} WHERE id >= ${START_ID} AND id < ${LAST_ID}), true);" )
  IGN=$( psql ${PG_OPT} -U ${OWNER} -t -q -d "${DATABASE}" -c "UPDATE $T SET id=nextval('${T}_id_seq') ${WHERE};" )
  echo "UPDATED ${FIX} records"
  psql -q -d "${DATABASE}" -c "ALTER TABLE ${T} ENABLE TRIGGER ALL;"
done

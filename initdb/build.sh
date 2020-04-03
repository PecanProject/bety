#!/bin/bash


NETWORK=$(docker network ls | awk '/_bety/ { print $2 }')
if [ "${NETWORK}" == "" ]; then
  NETWORK=$(docker network ls | awk '/_pecan/ { print $2 }')
  if [ "${NETWORK}" == "" ]; then 
    echo "ERR : network (pecan or bety) not found."
    exit -1
  fi
fi
echo "INF : will use $NETWORK"

POSTGRES=$(docker ps --filter network=${NETWORK} --filter name=postgres --format "{{.ID}} : {{.Names}}")
if [ "${POSTGRES}" == "" ]; then
  echo "ERR : no postgres found in network"
  exit -1
fi
echo "INF : will connect to ${POSTGRES}"

#docker-compose down
#docker volume rm bety_postgres

docker build --no-cache --network ${NETWORK} --tag pecan/db:latest .
docker images pecan/db

#docker-compose up -d postgres
#sleep 10
#docker run --network bety_bety -ti --rm pecan/db

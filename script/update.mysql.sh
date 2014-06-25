#!/bin/bash

set -x

# command to connect to database
export CMD="mysql -u bety -pbety"

# load latest dump of the database
curl -o betydump.gz https://ebi-forecast.igb.illinois.edu/pecan/dump/betydump.mysql.gz

echo "drop database if exists bety; create database bety;" | ${CMD}

gunzip -c betydump.gz | grep -v 'DEFINER' | ${CMD} bety
rm betydump.gz

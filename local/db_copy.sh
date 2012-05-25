#!/bin/bash

lockfile="/home/share/archive/analysis.lck"

if [[ $1 =~ ^[^Yy]$ ]] || [[ $1 == "" ]]; then
  if [ -e $lockfile ]; then
    echo "Already running or lock file not removed!"
    read -p "Do you wish to run the script anyways? (y/n)" yn
  fi
fi

if [ ! -e $lockfile ] || [[ $yn =~ ^[Yy]$ ]] || [[ $1 =~ ^[Yy]$ ]]; then
  touch $lockfile

  DB_USER="ebi_user"
  DB_PASSWORD="mScGKxhPhdq"
  DB="ebi_analysis"
  IGNORE=" --ignore-table=ebi_production.counties --ignore-table=ebi_production.county_boundaries --ignore-table=ebi_production.county_paths --ignore-table=ebi_production.locations_yields --ignore-table=ebi_production.plants --ignore-table=ebi_production.drop_me "

  echo "Backing up $DB to $DB-backup.sql"
  mysqldump $DB -u $DB_USER -p$DB_PASSWORD $IGNORE > /home/share/archive/$DB-backup.sql


  echo "Dropping tables from $DB"
  mysqldump $DB -u $DB_USER -p$DB_PASSWORD $IGNORE --add-drop-table --no-data | grep ^DROP | mysql -u $DB_USER -p$DB_PASSWORD $DB

  echo "Transfering tables from ebi_production to $DB"
  mysqldump $IGNORE -u $DB_USER -p$DB_PASSWORD ebi_production| mysql -u $DB_USER -p$DB_PASSWORD $DB
  echo "Removing -1 traits/yields from $DB"
  mysql -u $DB_USER -p$DB_PASSWORD $DB --execute="delete from traits where checked = -1; delete from yields where checked = -1"

  echo "Done!"
  rm $lockfile
fi

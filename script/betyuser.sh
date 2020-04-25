#!/bin/bash

if [ $# != 6 ]; then
  echo "$0 username password fullname email data_access page_access"
  echo "data access : 1=Restricted, 2=Internal, 3=External, 4=Public"
  echo "page_access : 1=Admin,      2=Manager,  3=Creator,  4=Viewer"
  exit 1
fi

LOGIN="$1"
PASSWORD="$2"
NAME="$3"
EMAIL="$4"
ACCESS=${5:-2}
PAGE=${6:-2}

SALT="${LOGIN}"

COUNT=10

DIGEST="${SECRET_KEY_BASE}"
for x in $(seq ${COUNT}); do
  DIGEST=$(echo -n "${DIGEST}--${SALT}--${PASSWORD}--${SECRET_KEY_BASE}" | sha1sum | awk '{print $1}')
done

psql -q -h postgres -U bety -t -c "INSERT INTO users (login, name, email, crypted_password, salt, access_level, page_access_level, created_at, updated_at) VALUES ('${LOGIN}', '${NAME}', '${EMAIL}', '${DIGEST}', '${SALT}', ${ACCESS}, ${PAGE}, NOW(), NOW())"

if [ $? == 0 ]; then
  echo "User ($LOGIN) has been added to database"
else
  echo "Could not add user to database"
fi

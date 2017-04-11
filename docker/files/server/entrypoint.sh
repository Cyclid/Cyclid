#!/usr/bin/env bash

# Reconfigure Cyclid
sed -i -e "s/MYSQL_USER/${MYSQL_USER}/" /etc/cyclid/config
sed -i -e "s/MYSQL_PASSWORD/${MYSQL_PASSWORD}/" /etc/cyclid/config
sed -i -e "s/MYSQL_HOST/${MYSQL_HOST}/" /etc/cyclid/config
sed -i -e "s/MYSQL_DATABASE/${MYSQL_DATABASE}/" /etc/cyclid/config

# Create the DB schema, if required
# XXX Need a better way to do this
if [ "x${CYCLID_DB_INIT}" == "xtrue" ]; then
  if [ -f /.dbinit ]; then
    echo "Cyclid database already initialised."
  else
    echo "Initialising Cyclid database."

    echo "CREATE DATABASE ${MYSQL_DATABASE}" | mysql -u ${MYSQL_USER} --password=${MYSQL_PASSWORD} -h ${MYSQL_HOST}
    cyclid-db-init ${ADMIN_SECRET} ${ADMIN_PASSWORD} && touch .dbinit
  fi
fi

# Start Cyclid under Unicorn
unicorn -E production -c /var/lib/cyclid/unicorn.rb

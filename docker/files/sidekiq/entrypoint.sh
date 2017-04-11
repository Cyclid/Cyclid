#!/usr/bin/env bash

# Reconfigure Cyclid
sed -i -e "s/MYSQL_USER/${MYSQL_USER}/" /etc/cyclid/config
sed -i -e "s/MYSQL_PASSWORD/${MYSQL_PASSWORD}/" /etc/cyclid/config
sed -i -e "s/MYSQL_HOST/${MYSQL_HOST}/" /etc/cyclid/config
sed -i -e "s/MYSQL_DATABASE/${MYSQL_DATABASE}/" /etc/cyclid/config

# Start Cyclid under Sidekiq
sidekiq -e production -P /var/run/cyclid/sidekiq.pid -L /var/log/cyclid/sidekiq.log -r /var/lib/cyclid/sidekiq.rb

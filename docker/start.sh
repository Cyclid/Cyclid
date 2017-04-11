#!/bin/bash
_MYSQL_PASSWORD=cyclid

# cyclid-db
docker run  --detach \
            -e MYSQL_ROOT_PASSWORD=${_MYSQL_PASSWORD} \
            -P \
            --name cyclid-db \
            mysql

# cyclid-redis
docker run  --detach \
            -P \
            --name cyclid-redis \
            redis

# cyclid-server
docker run  --detach \
            -e MYSQL_HOST='cyclid-db' \
            -e MYSQL_USER='root' \
            -e MYSQL_PASSWORD='cyclid' \
            -e CYCLID_DB_INIT=true \
            -p 8361:8361/tcp \
            --name cyclid-server \
            --link cyclid-db:cyclid-db \
            --link cyclid-redis:cyclid-redis \
            cyclid/server

# cyclid-sidekiq
docker run  --detach \
            -e MYSQL_HOST='cyclid-db' \
            -e MYSQL_USER='root' \
            -e MYSQL_PASSWORD='cyclid' \
            -v /var/run/docker.sock:/var/run/docker.sock \
            --name cyclid-sidekiq \
            --link cyclid-db:cyclid-db \
            --link cyclid-redis:cyclid-redis \
            cyclid/sidekiq

FROM ubuntu:trusty

# Gather MySQL database connection information
ARG MYSQL_HOST
ARG MYSQL_DATABASE=cyclid
ARG MYSQL_USER
ARG MYSQL_PASSWORD

# Initial admin HMAC secret & password
ARG ADMIN_SECRET=fe150f3939ed0419f32f8079482380f5cc54885a381904c15d861e8dc5989286
ARG ADMIN_PASSWORD=cyclid

# Redis server for Sidekiq worker queues
ARG REDIS_URL=redis://cyclid-redis:6379

# Cyclid runs on port 8361
EXPOSE 8361

# Install dependencies
RUN apt-get update
RUN apt-get install -qy software-properties-common
RUN add-apt-repository ppa:brightbox/ruby-ng
RUN apt-get update
RUN apt-get install -qy ruby2.3 ruby2.3-dev build-essential cmake mysql-client libmysqlclient-dev libsasl2-dev
RUN mkdir -p /var/lib/cyclid /var/run/cyclid /etc/cyclid /var/log/cyclid

# Install Cyclid & Unicorn
RUN gem install cyclid
RUN gem install mysql2
RUN gem install unicorn

COPY files/config /etc/cyclid/config
COPY files/config.ru /var/lib/cyclid/config.ru
COPY files/unicorn.rb /var/lib/cyclid/unicorn.rb
COPY files/entrypoint.sh /entrypoint.sh

# Expose the Docker socket
# XXX Don't need this for the server, just Sidekiq
#VOLUME /var/run/docker.sock

ENTRYPOINT /entrypoint.sh

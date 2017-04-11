#!/bin/bash

docker build -t cyclid/server -f Dockerfile.server .
docker build -t cyclid/sidekiq -f Dockerfile.sidekiq .

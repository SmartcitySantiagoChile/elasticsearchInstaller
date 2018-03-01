#!/bin/bash

# install requirement
apt-get update
apt-get install build-essential tcl

# install redis 
apt-get install redis-server

# we will use redis as cache so we have to edit 
sed -i 's/# maxmemory <bytes>/maxmemory 128mb/g' /etc/redis/redis.conf

# restart redis
systemctl restart redis-server.service

# enable redis on system boot
systemctl enable redis-server.service

systemctl status redis-server.service

echo "Done. Redis-server is now running"


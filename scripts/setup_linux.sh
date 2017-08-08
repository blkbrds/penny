#!/bin/bash

set -e;

# swift & vapor
eval "$(curl -sL https://apt.vapor.sh)";
sudo apt-get install -y \
    clang-3.8 \
    clang \
    libicu-dev \
    swift \
    vapor \
    --no-install-recommends;
eval "$(curl -sL check.vapor.sh)";

# mysql headers
sudo apt-get install -y \
    libmysqlclient20 \
    libmysqlclient-dev \
    cmysql \
    --no-install-recommends;

# mysql server - root@pass
sudo apt-get install -y mysql-server --no-install-recommends;

# nginx
sudo apt-get install -y nginx --no-install-recommends;

# supervisor
sudo apt-get install -y supervisor --no-install-recommends;


#!/bin/bash

set -e;

# rm -rf .build

dc() {
    docker-compose -f ./docker/docker-compose.yml "$@";
};

dc down;
dc build vapor;
dc up -d proxy
dc up -d --build cftr-api;

#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Please give the key name mykey1 or mykey2"
    exit
fi

key=$1
PRIVATE_KEY=$(docker compose -f ../zbc-development/docker-compose.validator.yml exec validator evmosd --home /root/.evmosd keys unsafe-export-eth-key $key --keyring-backend test)
echo "Get address from private key: $PRIVATE_KEY"
docker compose -f docker-compose.yml run app python demo_test_high_level.py $PRIVATE_KEY

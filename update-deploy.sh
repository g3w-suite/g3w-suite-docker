#!/bin/bash

docker build -f Dockerfile.g3wsuite.dockerfile -t g3wsuite/g3w-suite:dev-processing --no-cache .

docker compose -f docker-compose-consumer.yml down
docker compose -f docker-compose-consumer.yml up -d

#!/bin/bash
# Include environment and library function
source "$(dirname $0)/.env"


# 0. Network Container Array Setting by using docker-compose.yaml
CONTAINER_ARRAY=($(eval echo $(yq r ${HYPER_NETWORK_HOME}/${HYPER_NETWORK_DOCKER_COMPOSE_FILENAME} services.*.container_name)))
IMAGE_ARRAY=($(eval echo $(yq r ${HYPER_NETWORK_HOME}/${HYPER_NETWORK_DOCKER_COMPOSE_FILENAME} services.*.image)))

TOTAL_CONTAINER_COUNT=$(expr ${#CONTAINER_ARRAY[@]} - 1)
TOTAL_CONTAINER_COUNT=${TOTAL_CONTAINER_COUNT:--1}


# 1. CHECK the liveness of Network Containers
for INDEX in $(seq 0 ${TOTAL_CONTAINER_COUNT})
do
  CURRENT_IMAGE=${IMAGE_ARRAY[${INDEX}]}
  CURRENT_CONTAINER=${CONTAINER_ARRAY[${INDEX}]}

  docker ps | grep ${CURRENT_CONTAINER} | grep ${CURRENT_IMAGE} 2>&1 >/dev/null

  if [ $? -eq 0 ]
  then
    echo
    echo "[SUCCESS] ${CURRENT_CONTAINER} [OK]"
  else
    echo
    echo "[ERROR] ${CURRENT_CONTAINER} is not running! [FAILED]"
    echo
    print_network_dependency_info ${CURRENT_CONTAINER};
  fi
done

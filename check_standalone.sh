#!/bin/bash

# Execution UserID Setting (User Setting)
EXEC_USER_ID="rolroralra"


# Home Directory Setting (User Setting)
USER_HOME=${USER_HOME:-/home/rolroralra}
DOCKER_COMPOSE_HOME="${USER_HOME}/rolroralra-stg-v2.3"
DOCKER_COMPOSE_FILENAME="server1.yaml"


if [ $(whoami) != "${EXEC_USER_ID}" ]
then
  echo "[ERROR] Script must be run as user: ${EXEC_USER_ID}!";
  exit 255
fi


# This shellscript is dependent on "yq"
which yq 2>&1 >/dev/null
if [ $? -ne 0 ]
then
  echo "[ERROR] There is no \"yq\". Please install yq. (https://github.com/mikefarah/yq/releases)"
  exit 1;
fi


# Include Docker-Compose Environment Variable
source ${DOCKER_COMPOSE_HOME}/.env


# Function for convert multiline string to array (Utility)
string_join() {
  local __DELIMETER=$1
  shift
  local __PARAMETER=$1
  shift
  printf %s "${__PARAMETER}" "${@/#/${__DELIMETER}}"
}


# Function for printing the Container Name Array in docker-compose yaml file
print_container_names() {
  NL=" "
  for INPUT_ARG in $@
  do
    eval echo -n $(yq r ${DOCKER_COMPOSE_HOME}/${DOCKER_COMPOSE_FILENAME} services.${INPUT_ARG}*.container_name)
    echo -n " "
  done
  NL="\n"
}


# Function for printing Container Dependency Array in docker-compose yaml file
print_dependency_array() {
  if [ $# -ge 1 ]
  then
    IFS_OLD=${IFS}
    IFS=$'\n'

    local DEPENDENCY_ARRAY=($(eval echo $(yq r ${DOCKER_COMPOSE_HOME}/${DOCKER_COMPOSE_FILENAME} services[$1].depends_on | sed 's/- //g')))

    IFS=${IFS_OLD}

    string_join " " ${DEPENDENCY_ARRAY[@]}

    #for DEPENDENCY in ${DEPENDENCY_ARRAY}
    #do
    #  echo -n ${DEPENDENCY}
    #  echo -n " "
    #done
  fi
}


# Function for printing the Container Dependency Information
print_dependency_info() {
  local DEPENDENCY_ARRAY=($(print_dependency_array $1))

  if [ ${#DEPENDENCY_ARRAY[@]} -gt 0 ]
  then
      echo "[WARNING] \"$1\" is dependent on $(string_join ", " ${DEPENDENCY_ARRAY[@]})"
      echo "[INFO] How to run containers of network"
      echo "$ cd ${DOCKER_COMPOSE_HOME}; docker-compose -f ${DOCKER_COMPOSE_FILENAME} up -d ${DEPENDENCY_ARRAY[@]} $1"
  elif [ ${#DEPENDENCY_ARRAY[@]} -eq 0 ]
  then
      echo "[INFO] How to run containers of network"
      echo "$ cd ${DOCKER_COMPOSE_HOME}; docker-compose -f ${DOCKER_COMPOSE_FILENAME} up -d $1"
  fi

  # Manual Printing (User Setting)
  case $1 in
    *"couchdb"*);;
    *"peer"*);;
    *"orderer"*);;
    *"zookeeper"*);;
    *"kafka"*);;
    *"api-server"*);;
    *"event-server"*);;
  esac
}


# 0. Container Array Initialization by using docker-compose yaml file
CONTAINER_ARRAY=($(eval echo $(yq r ${DOCKER_COMPOSE_HOME}/${DOCKER_COMPOSE_FILENAME} services.*.container_name)))
IMAGE_ARRAY=($(eval echo $(yq r ${DOCKER_COMPOSE_HOME}/${DOCKER_COMPOSE_FILENAME} services.*.image)))

TOTAL_CONTAINER_COUNT=$(expr ${#CONTAINER_ARRAY[@]} - 1)
TOTAL_CONTAINER_COUNT=${TOTAL_CONTAINER_COUNT:--1}


# 1. CHECK the liveness of services in docker-compose yaml file
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
    print_dependency_info ${CURRENT_CONTAINER};
  fi
done

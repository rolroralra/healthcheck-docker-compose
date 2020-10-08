# healthcheck-docker-compose
Shellscript for checking liveness of services in docker-compose.yaml

```bash
#!/bin/bash

# Execution UserID Setting (User Setting)
EXEC_USER_ID="nexledger"


# Home Directory Setting (User Setting)
NEXLEDGER_HOME=${NEXLEDGER_HOME:-/home/gdsecurity/install}
HYPER_NETWORK_HOME="${NEXLEDGER_HOME}/network/sample"
GD_TOOL_WAS_HOME="${NEXLEDGER_HOME}/was"


if [ $(whoami) != "${EXEC_USER_ID}" ]
then
  echo "[ERROR] Script must be run as user: ${EXEC_USER_ID}!";
  exit 255
fi


# This shellscript is dependent on "yq"
which yq 2>&1 >/dev/null
if [ $? -ne 0 ]
then
  echo "[ERROR] There is no \"yq\". Please install yq. (https://github.com/mkikefarah/yq/releases)"
  exit 1;
fi


# Include Hyperledger Network Environment Variable
source ${HYPER_NETWORK_HOME}/.env


# Function for convert multiline string to array (Utility)
string_join() {
  local __DELIMETER=$1
  shift
  local __PARAMETER=$1
  shift
  printf %s "${__PARAMETER}" "${@/#/${__DELIMETER}}"
}


# Function for printing the Nexledger.H Network Container Name Array
print_network_container_name() {
  NL=" "
  for INPUT_ARG in $@
  do
    eval echo -n $(yq r ${HYPER_NETWORK_HOME}/docker-compose.y*ml services.${INPUT_ARG}*.container_name)
    echo -n " "
  done
  NL="\n"
}


# Function for printing the Nexledger.H Network Container Dependency Array
print_network_dependency_list() {
  if [ $# -ge 1 ]
  then
    IFS_OLD=${IFS}
    IFS=$'\n'

    local DEPENDENCY_ARRAY=($(eval echo $(yq r ${HYPER_NETWORK_HOME}/docker-compose.yaml services[$1].depends_on | sed 's/- //g')))

    IFS=${IFS_OLD}

    string_join " " ${DEPENDENCY_ARRAY[@]}

    #for DEPENDENCY in ${DEPENDENCY_ARRAY}
    #do
    #  echo -n ${DEPENDENCY}
    #  echo -n " "
    #done
  fi
}


# Function for printing the Nexledger.H Network Container Dependency Information
print_network_dependency_info() {
  local DEPENDENCY_ARRAY=($(print_network_dependency_list $1))

  if [ ${#DEPENDENCY_ARRAY[@]} -gt 0 ]
  then
      echo "[WARNING] \"$1\" is dependent on $(string_join ", " ${DEPENDENCY_ARRAY[@]})"
      echo "[INFO] How to run containers of Nexledger.H network"
      echo "$ cd ${HYPER_NETWORK_HOME}; docker-compose up -d ${DEPENDENCY_ARRAY[@]} $1"
  elif [ ${#DEPENDENCY_ARRAY[@]} -eq 0 ]
  then
      echo "[INFO] How to run containers of Nexledger.H network"
      echo "$ cd ${HYPER_NETWORK_HOME}; docker-compose up -d $1"
  fi

  # Manual Printing
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


# 0. Nexledger.H Network Container Array Setting by using docker-compose.yaml
CONTAINER_ARRAY=($(eval echo $(yq r ${HYPER_NETWORK_HOME}/docker-compose.y*ml services.*.container_name)))
IMAGE_ARRAY=($(eval echo $(yq r ${HYPER_NETWORK_HOME}/docker-compose.y*ml services.*.image)))

TOTAL_CONTAINER_COUNT=$(expr ${#CONTAINER_ARRAY[@]} - 1)
TOTAL_CONTAINER_COUNT=${TOTAL_CONTAINER_COUNT:--1}


# 1. CHECK the liveness of Nexledger.H Network Containers
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
```

---
### .env
[go to source code](.env)

---
### check.sh
[go to source code](check.sh)

---
### include.sh
[go to source code](./include/include.sh)

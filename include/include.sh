#!/bin/bash

# This shellscript is dependent on "yq"
which yq 2>&1 >/dev/null
if [ $? -ne 0 ]
then
  echo "[ERROR] There is no \"yq\". Please install yq. (https://github.com/mikefarah/yq/releases)"
  exit 1;
fi


# Home Directory Default Setting (Don't touch!)
PROJECT_HOME=${PROJECT_HOME:-${HOME:-/home/gdsecurity}/install/rolroralra}
HYPER_NETWORK_HOME=${HYPER_NETWORK_HOME:-${PROJECT_HOME}/network}
GD_TOOL_WAS_HOME=${GD_TOOL_WAS_HOME:-${PROJECT_HOME}/was}


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


# Function for printing the Hyperledger Network Container Name Array
print_network_container_name() {
  NL=" "
  for INPUT_ARG in $@
  do
    eval echo -n $(yq r ${HYPER_NETWORK_HOME}/docker-compose.y*ml services.${INPUT_ARG}*.container_name)
    echo -n " "
  done
  NL="\n"
}


# Function for printing the Hyperledger Network Container Dependency Array
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


# Function for printing the Hyperledger Network Container Dependency Information
print_network_dependency_info() {
  local DEPENDENCY_ARRAY=($(print_network_dependency_list $1))

  if [ ${#DEPENDENCY_ARRAY[@]} -gt 0 ]
  then
      echo "[WARNING] \"$1\" is dependent on $(string_join ", " ${DEPENDENCY_ARRAY[@]})"
      echo "[INFO] How to run containers of Hyperledger network"
      echo "$ cd ${HYPER_NETWORK_HOME}; docker-compose up -d ${DEPENDENCY_ARRAY[@]} $1"
  elif [ ${#DEPENDENCY_ARRAY[@]} -eq 0 ]
  then
      echo "[INFO] How to run containers of Hyperledger network"
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

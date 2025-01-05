#!/bin/bash

_ENV_PROPS=./env-ocp.properties
if [[ ! -f ${_ENV_PROPS} ]]; then
  echo "Error, file ${_ENV_PROPS} not in folder $(pwd)"
  exit 1
fi

source ${_ENV_PROPS}

echo "===>> Delete namespace"
kubectl delete -f ./${_FOLDER}/bamoe-ns.yaml

echo "===>> Delete SCC"
kubectl delete -f ./${_FOLDER}/pgadmin/scc.yaml


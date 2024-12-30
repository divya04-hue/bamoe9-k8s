#!/bin/bash

_ENV_PROPS=./env.properties
if [[ ! -f ${_ENV_PROPS} ]]; then
  echo "===>> Error, file ${_ENV_PROPS} not in folder $(pwd)"
  exit 1
fi

source ${_ENV_PROPS}

# namespace
echo "===>> Create namespace"
kubectl apply -f ./${_FOLDER}/bamoe-ns.yaml 

#-----------------------
# postgres
echo "===>> Create Postgres resources"
kubectl create configmap -n ${_NS} pg-init-db --from-file=init.sql=./${_FOLDER}/postgres/${_INIT_DB_FILE}
kubectl apply -f ./${_FOLDER}/postgres/${_CR_NAME_PV}.yaml 
kubectl apply -f ./${_FOLDER}/postgres/${_CR_NAME_PVC}.yaml 
kubectl apply -f ./${_FOLDER}/postgres/${_CR_NAME_SECR_PWD_POSTGRES}.yaml 
kubectl apply -f ./${_FOLDER}/postgres/${_CR_NAME_DEP_POSTGRES}.yaml 

#-----------------------
# pgadmin
echo "===>> Create PGAdmin resources"
kubectl create configmap -n ${_NS} pgadmin-config --from-file=servers.json=./${_FOLDER}/pgadmin/servers.json
kubectl create configmap -n ${_NS} pgadmin-passwd --from-file=my-passwords.pgpass=./${_FOLDER}/pgadmin/my-passwords.pgpass
kubectl apply -f ./${_FOLDER}/pgadmin/${_CR_NAME_DEP_PGADMIN}.yaml 

#-----------------------
# keycloak
echo "===>> Create Keycloak resources"
kubectl create configmap -n ${_NS} ${_REALM_NAME} --from-file=${_REALM_NAME}.json=./${_FOLDER}/keycloak/custom-realm.json 
kubectl apply -f ./${_FOLDER}/keycloak/${_CR_NAME_DEP_KC}.yaml 

#-----------------------
# bamoe application
echo "===>> Create BAMOE resources"
kubectl apply -f ./${_FOLDER}/bamoe/${_CR_NAME_DEP_BAMOE}.yaml 

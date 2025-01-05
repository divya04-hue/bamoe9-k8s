# Manual deployment steps

Before run any command set all variables in shell env.
```
# choose one between

source ./env.properties

# or
source ./env-ocp.properties
```

## create namespace
```
kubectl apply -f ./${_FOLDER}/bamoe-ns.yaml 
```

## create postgres (only minikube or other without storage classes)
```
kubectl create configmap -n ${_NS} pg-init-db --from-file=init.sql=./${_FOLDER}/postgres/${_INIT_DB_FILE}
kubectl apply -f ./${_FOLDER}/postgres/${_CR_NAME_PV}.yaml 
kubectl apply -f ./${_FOLDER}/postgres/${_CR_NAME_PVC}.yaml 
kubectl apply -f ./${_FOLDER}/postgres/${_CR_NAME_SECR_PWD_POSTGRES}.yaml 
kubectl apply -f ./${_FOLDER}/postgres/${_CR_NAME_DEP_POSTGRES}.yaml 
```

## create postgres (Openshift only)
```
kubectl create configmap -n ${_NS} pg-init-db --from-file=init.sql=./${_FOLDER}/postgres/${_INIT_DB_FILE}
kubectl apply -f ./${_FOLDER}/postgres/${_CR_NAME_PVC}.yaml 
kubectl apply -f ./${_FOLDER}/postgres/${_CR_NAME_DEP_POSTGRES}.yaml 
```


## create pgadmin (K8S only)
```
kubectl create configmap -n ${_NS} pgadmin-config --from-file=servers.json=./${_FOLDER}/pgadmin/servers.json
kubectl create configmap -n ${_NS} pgadmin-passwd --from-file=my-passwords.pgpass=./${_FOLDER}/pgadmin/my-passwords.pgpass
kubectl apply -f ./${_FOLDER}/pgadmin/${_CR_NAME_DEP_PGADMIN}.yaml 

```

## create pgadmin (Openshift only)
```
kubectl create -f ./${_FOLDER}/pgadmin/scc.yaml
kubectl apply -f ./${_FOLDER}/pgadmin/roles.yaml
kubectl create configmap -n ${_NS} pgadmin-config --from-file=servers.json=./${_FOLDER}/pgadmin/servers.json
kubectl create configmap -n ${_NS} pgadmin-passwd --from-file=my-passwords.pgpass=./${_FOLDER}/pgadmin/my-passwords.pgpass
kubectl apply -f ./${_FOLDER}/pgadmin/${_CR_NAME_DEP_PGADMIN}.yaml 
kubectl apply -f ./${_FOLDER}/pgadmin/route.yaml
```

## create keycloak (K8S only)
```
kubectl create configmap -n ${_NS} ${_REALM_NAME} --from-file=${_REALM_NAME}.json=./${_FOLDER}/keycloak/custom-realm.json 
kubectl apply -f ./${_FOLDER}/keycloak/${_CR_NAME_DEP_KC}.yaml 
```

## create keycloak (Openshift only)
```
kubectl create configmap -n ${_NS} ${_REALM_NAME} --from-file=${_REALM_NAME}.json=./${_FOLDER}/keycloak/custom-realm.json 
kubectl apply -f ./${_FOLDER}/keycloak/${_CR_NAME_DEP_KC}.yaml 
kubectl apply -f ./${_FOLDER}/keycloak/route.yaml
```

## create bamoe application (K8S only)
```
kubectl apply -f ./${_FOLDER}/bamoe/${_CR_NAME_DEP_BAMOE}.yaml 
```

## create bamoe application (Openshift only)
```
kubectl apply -f ./${_FOLDER}/bamoe/${_CR_NAME_DEP_BAMOE}.yaml 
kubectl apply -f ./${_FOLDER}/bamoe/route.yaml 
KEYCLOAK_URL="http://"$(oc get route -n ${_NS} keycloak -o jsonpath='{.spec.host}')
_OIDC_URL="${KEYCLOAK_URL}/realms/my-realm-1"
kubectl set env deployment/bamoe -c frontend QUARKUS_OIDC_AUTH_SERVER_URL=${_OIDC_URL}
kubectl set env deployment/bamoe -c frontend QUARKUS_OIDC_CLIENT_AUTH_SERVER_URL=${_OIDC_URL}

```


# Manual undeployment steps

## remove all
```
kubectl delete -f ./${_FOLDER}/bamoe-ns.yaml

# only K8S
kubectl delete -f ./${_FOLDER}/postgres/postgres-bamoe-pv.yaml 

# only OCP
kubectl delete -f ./${_FOLDER}/pgadmin/scc.yaml
kubectl delete -f ./${_FOLDER}/pgadmin/roles.yaml

```

```
# if minikube enter with ssh then remove PV storage from hostPath
minikube ssh
cd /data
sudo rm -fr ./postgres-bamoe
exit
```

## remove postgres
```
kubectl delete configmap -n ${_NS} pg-init-db
kubectl delete -f ./${_FOLDER}/postgres/postgres-pwd-secret.yaml 
kubectl delete -f ./${_FOLDER}/postgres/postgres.yaml 
kubectl delete -f ./${_FOLDER}/postgres/postgres-bamoe-pvc.yaml 
kubectl delete -f ./${_FOLDER}/postgres/postgres-bamoe-pv.yaml 
```

## remove pgadmin
```
kubectl delete configmap -n ${_NS} pgadmin-config
kubectl delete configmap -n ${_NS} pgadmin-passwd
kubectl delete -f ./${_FOLDER}/pgadmin/pgadmin.yaml 
```

## remove keycloak
```
kubectl delete configmap -n ${_NS} ${_REALM_NAME}
kubectl delete -f ./${_FOLDER}/keycloak/keycloak.yaml 
```

## remove bamoe
```
kubectl delete -f ./${_FOLDER}/bamoe/bamoe.yaml 
```



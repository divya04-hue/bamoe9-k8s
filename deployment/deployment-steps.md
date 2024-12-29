# Deployment steps

#---------------------------------------------------------

# Before run any command set all variables in shell env. see 'Environment variables' section in 'configuration-steps.md' 

#-----------------------
# namespace
kubectl apply -f ./${_FOLDER}/bamoe-k8s.yaml 

#-----------------------
# postgres
kubectl create configmap -n ${_NS} pg-init-db --from-file=init.sql=./${_FOLDER}/postgres/${_INIT_DB_FILE}
kubectl apply -f ./${_FOLDER}/postgres/${_CR_NAME_PV}.yaml 
kubectl apply -f ./${_FOLDER}/postgres/${_CR_NAME_PVC}.yaml 
kubectl apply -f ./${_FOLDER}/postgres/${_CR_NAME_SECR_PWD_POSTGRES}.yaml 
kubectl apply -f ./${_FOLDER}/postgres/${_CR_NAME_DEP_POSTGRES}.yaml 

#-----------------------
# pgadmin
kubectl create configmap -n ${_NS} pgadmin-config --from-file=servers.json=./${_FOLDER}/pgadmin/servers.json
kubectl create configmap -n ${_NS} pgadmin-passwd --from-file=my-passwords.pgpass=./${_FOLDER}/pgadmin/my-passwords.pgpass
kubectl apply -f ./${_FOLDER}/pgadmin/${_CR_NAME_DEP_PGADMIN}.yaml 

#-----------------------
# keycloak
kubectl create configmap -n ${_NS} ${_REALM_NAME} --from-file=${_REALM_NAME}.json=./${_FOLDER}/keycloak/custom-realm.json 
kubectl apply -f ./${_FOLDER}/keycloak/${_CR_NAME_DEP_KC}.yaml 

#-----------------------
# bamoe application
kubectl apply -f ./${_FOLDER}/bamoe/${_CR_NAME_DEP_BAMOE}.yaml 



#------------------------------------
# rimozione CR

# tutto
kubectl delete ns bamoe-k8s
kubectl delete -f ./${_FOLDER}/postgres/postgres-bamoe-pv.yaml 

# if minikube remove PV storage from hostPath
    minikube ssh
    cd /data
    sudo rm -fr ./postgres-bamoe
    exit

# postgres
kubectl delete configmap -n ${_NS} pg-init-db
kubectl delete -f ./${_FOLDER}/postgres/postgres-pwd-secret.yaml 
kubectl delete -f ./${_FOLDER}/postgres/postgres.yaml 
kubectl delete -f ./${_FOLDER}/postgres/postgres-bamoe-pvc.yaml 
kubectl delete -f ./${_FOLDER}/postgres/postgres-bamoe-pv.yaml 

# pgadmin
kubectl delete configmap -n ${_NS} pgadmin-config
kubectl delete configmap -n ${_NS} pgadmin-passwd
kubectl delete -f ./${_FOLDER}/pgadmin/pgadmin.yaml 

# keycloak
kubectl delete configmap -n ${_NS} ${_REALM_NAME}
kubectl delete -f ./${_FOLDER}/keycloak/keycloak.yaml 

# bamoe
kubectl delete -f ./${_FOLDER}/bamoe/bamoe.yaml 


#------------------------------------
POSTGRES_POD=$(kubectl get pods -n bamoe-k8s --no-headers | grep postgres | awk '{print $1}')

kubectl logs -f -n bamoe-k8s ${POSTGRES_POD}

kubectl exec --stdin --tty -n bamoe-k8s ${POSTGRES_POD} -- /bin/bash

cat /docker-entrypoint-initdb.d/init.sql

PGPASSWORD=myPgPassword psql -h localhost -p 5432 -U postgres


#------------------------------------
PGADMIN_POD=$(kubectl get pods -n bamoe-k8s --no-headers | grep pgadmin | awk '{print $1}')

kubectl logs -f -n bamoe-k8s ${PGADMIN_POD}

kubectl exec --stdin --tty -n bamoe-k8s ${PGADMIN_POD} -- /bin/bash


#------------------------------------
KC_POD=$(kubectl get pods -n bamoe-k8s --no-headers | grep keycloak | awk '{print $1}')
kubectl exec --stdin --tty -n bamoe-k8s ${KC_POD} -- /bin/bash

cat /opt/keycloak/data/import/custom-realm.json

#------------------------------------
BAMOE_POD=$(kubectl get pods -n bamoe-k8s --no-headers | grep bamoe | awk '{print $1}')

kubectl logs -f -c backend -n bamoe-k8s ${BAMOE_POD}

kubectl logs -f -c frontend -n bamoe-k8s ${BAMOE_POD}

kubectl exec --stdin --tty -c frontend -n bamoe-k8s ${BAMOE_POD} -- /bin/bash

kubectl exec --stdin --tty -c backend -n bamoe-k8s ${BAMOE_POD} -- /bin/bash


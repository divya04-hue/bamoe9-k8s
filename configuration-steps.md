
# Configuration steps

```
# minikube

#--------------------------
# namespace

_NS=bamoe-k8s
_FOLDER=./cr

cat <<EOF > ./${_FOLDER}/${_NS}.yaml
kind: Namespace
apiVersion: v1
metadata:
  name: ${_NS}
  labels:
    kubernetes.io/metadata.name: ${_NS}
spec:
  finalizers:
    - kubernetes
EOF

#--------------------------
# storage

# PV
_FOLDER=./cr/postgres
_CR_NAME_PV=postgres-bamoe

cat <<EOF > ./${_FOLDER}/${_CR_NAME_PV}.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ${_CR_NAME_PV}
spec:
  accessModes:
    - ReadWriteOnce
  capacity:
    storage: 5Gi
  hostPath:
    path: /data/${_CR_NAME_PV}/
EOF

_FOLDER=./cr/postgres
_CR_NAME_KC_PV=postgres-kc

cat <<EOF > ./${_FOLDER}/${_CR_NAME_KC_PV}.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ${_CR_NAME_KC_PV}
spec:
  accessModes:
    - ReadWriteOnce
  capacity:
    storage: 2Gi
  hostPath:
    path: /data/${_CR_NAME_KC_PV}/
EOF


# PVC
_FOLDER=./cr/postgres
_CR_NAME_PVC=postgres-bamoe-pvc

cat <<EOF > ./${_FOLDER}/${_CR_NAME_PVC}.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${_CR_NAME_PVC}
  namespace: ${_NS}
spec:
  storageClassName: ""
  volumeName: ${_CR_NAME_PV}
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
EOF


# PVC
_FOLDER=./cr/postgres
_CR_NAME_KC_PVC=postgres-kc-pvc

cat <<EOF > ./${_FOLDER}/${_CR_NAME_KC_PVC}.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${_CR_NAME_KC_PVC}
  namespace: ${_NS}
spec:
  storageClassName: ""
  volumeName: ${_CR_NAME_KC_PV}
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF

#------------------------------
# Postgres

# Secret
_PG_USER=postgres
_PG_PWD=$(echo "myPgPassword" | base64 )

_FOLDER=./cr/postgres
_CR_NAME_SECR_PWD_POSTGRES=postgres-pwd-secret

cat <<EOF > ./${_FOLDER}/${_CR_NAME_SECR_PWD_POSTGRES}.yaml
apiVersion: v1
kind: Secret
metadata:
  name: ${_CR_NAME_SECR_PWD_POSTGRES}
  namespace: ${_NS}
type: Opaque
data:
  password: ${_PG_PWD}
EOF

# Deployment
_FOLDER=./cr/postgres
_CR_NAME_DEP_POSTGRES=postgres

cat <<EOF > ./${_FOLDER}/${_CR_NAME_DEP_POSTGRES}.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${_CR_NAME_DEP_POSTGRES}
  namespace: ${_NS}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${_CR_NAME_DEP_POSTGRES}
  template:
    metadata:
      labels:
        app: ${_CR_NAME_DEP_POSTGRES}
    spec:
      containers:
        - name: postgres
          image: 'postgres'
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 5432
          env:
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: ${_CR_NAME_SECR_PWD_POSTGRES}
                  key: password            
          volumeMounts:
            - mountPath: /var/lib/postgresql/data
              name: postgresdata
            - mountPath: /docker-entrypoint-initdb.d
              name: pg-init-db
      volumes:
        - name: postgresdata
          persistentVolumeClaim:
            claimName: ${_CR_NAME_PVC}
        - name: pg-init-db
          configMap:
            name: pg-init-db    
---
apiVersion: v1
kind: Service
metadata:
  name: ${_CR_NAME_DEP_POSTGRES}
  namespace: ${_NS}
  labels:
    app: ${_CR_NAME_DEP_POSTGRES}
spec:
  selector:
    app: ${_CR_NAME_DEP_POSTGRES}
  ports:
    - protocol: TCP
      port: 5432
      targetPort: 5432
EOF

# PGADMIN
cat <<EOF > ./cr/pgadmin/servers.json
{
  "Servers": {
    "1": {
      "Name": "my-databases",
      "Group": "Servers",
      "Host": "postgres",
      "Port": 5432,
      "MaintenanceDB": "postgres",
      "Username": "postgres",
      "SSLMode": "disable",
      "PassFile": "/pgadmin4/myconfig/pgpass"
    }
}
EOF

cat <<EOF > ./cr/pgadmin/pgpass
postgres:5432:postgres:postgres:myPgPassword
postgres:5432:bamoe:postgres:myPgPassword
postgres:5432:keycloak:postgres:myPgPassword
postgres:5432:kogito:postgres:myPgPassword
EOF

_FOLDER=./cr/pgadmin
_CR_NAME_DEP_PGADMIN=pgadmin

cat <<EOF > ./${_FOLDER}/${_CR_NAME_DEP_PGADMIN}.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${_CR_NAME_DEP_PGADMIN}
  namespace: ${_NS}
spec:
  selector:
   matchLabels:
    app: ${_CR_NAME_DEP_PGADMIN}
  replicas: 1
  template:
    metadata:
      labels:
        app: ${_CR_NAME_DEP_PGADMIN}
    spec:
      containers:
        - name: pgadmin4
          image: 'dpage/pgadmin4:8.13.0'
          imagePullPolicy: IfNotPresent
          env:
            - name: PGADMIN_DEFAULT_EMAIL
              value: admin@example.com
            - name: PGADMIN_DEFAULT_PASSWORD
              value: admin
            - name: PGADMIN_PORT
              value: "80"
            - name: PGADMIN_SERVER_JSON_FILE
              value: "/pgadmin4/myconfig/servers.json"
            - name: PGPASS_FILE
              value: "/pgadmin4/myconfig/pgpass"
          ports:
            - containerPort: 80
              name: pgadminport
          volumeMounts:
            - name: pgadmin-config
              mountPath: /pgadmin4/myconfig
      volumes:
        - name: pgadmin-config
          configMap:
            name: pgadmin-config       
---
apiVersion: v1
kind: Service
metadata:
  name: ${_CR_NAME_DEP_PGADMIN}
  namespace: ${_NS}
  labels:
    app: ${_CR_NAME_DEP_PGADMIN}
spec:
  selector:
    app: ${_CR_NAME_DEP_PGADMIN}
  type: NodePort
  ports:
    - nodePort: 45200
      port: 80
      targetPort: 80
EOF


  
#------------------------------
# Keycloak

_FOLDER=./cr/keycloak
_CR_NAME_DEP_KC=keycloak
_REALM_NAME=custom-realm
cat <<EOF > ./${_FOLDER}/${_CR_NAME_DEP_KC}.yaml
apiVersion: v1
kind: Service
metadata:
  name: ${_CR_NAME_DEP_KC}
  namespace: ${_NS}
spec:
  selector:
    app: ${_CR_NAME_DEP_KC}
  type: NodePort
  ports:
    - nodePort: 45201
      port: 8080
      targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${_CR_NAME_DEP_KC}
  namespace: ${_NS}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${_CR_NAME_DEP_KC}
  template:
    metadata:
      labels:
        app: ${_CR_NAME_DEP_KC}
    spec:
      containers:
        - name: keycloak
          image: quay.io/keycloak/keycloak:latest
          args: ["start-dev", "--import-realm"]
          env:
            - name: KEYCLOAK_ADMIN
              value: admin
            - name: KEYCLOAK_ADMIN_PASSWORD
              value: admin
            - name: KC_DB
              value: postgres
            - name: KC_DB_URL
              value: jdbc:postgresql://postgres:5432/keycloak
            - name: KC_DB_USERNAME
              value: ${_PG_USER}
            - name: KC_DB_PASSWORD
              value: myPgPassword
          volumeMounts:
            - name: realm-config
              mountPath: /opt/keycloak/data/import
      volumes:
        - name: realm-config
          configMap:
            name: ${_REALM_NAME}
EOF

#---------------------------------------------------------

kubectl delete ns bamoe-k8s
kubectl delete pv postgres-bamoe-pv postgres-kc-pv

kubectl apply -f ./cr/bamoe-k8s.yaml 

kubectl apply -f ./cr/postgres/postgres-bamoe.yaml 
kubectl apply -f ./cr/postgres/postgres-bamoe-pvc.yaml 

kubectl apply -f ./cr/postgres/postgres-kc.yaml 
kubectl apply -f ./cr/postgres/postgres-kc-pvc.yaml 

kubectl apply -f ./cr/postgres/postgres-pwd-secret.yaml 

kubectl create configmap -n ${_NS} pg-init-db --from-file=init.sql=./cr/postgres/init.sql

kubectl apply -f ./cr/postgres/postgres.yaml 

kubectl create configmap -n ${_NS} pgadmin-config --from-file=servers.json=./cr/pgadmin/servers.json --from-file=pgpass=./cr/pgadmin/pgpass
kubectl apply -f ./cr/pgadmin/pgadmin.yaml 

_REALM_NAME=custom-realm
kubectl create configmap -n ${_NS} ${_REALM_NAME} --from-file=${_REALM_NAME}.json=./cr/keycloak/custom-realm.json 
kubectl apply -f ./cr/keycloak/keycloak.yaml 



#------------------------------------
POSTGRES_POD=$(oc get pods -n bamoe-k8s --no-headers | grep postgres | awk '{print $1}')

kubectl logs -f -n bamoe-k8s ${POSTGRES_POD}

kubectl exec --stdin --tty -n bamoe-k8s ${POSTGRES_POD} -- /bin/bash

cat /docker-entrypoint-initdb.d/init.sql

PGPASSWORD=myPgPassword psql -h localhost -p 5432 -U postgres


#------------------------------------
PGADMIN_POD=$(oc get pods -n bamoe-k8s --no-headers | grep pgadmin | awk '{print $1}')
kubectl exec --stdin --tty -n bamoe-k8s ${PGADMIN_POD} -- /bin/bash


#------------------------------------
KC_POD=$(oc get pods -n bamoe-k8s --no-headers | grep keycloak | awk '{print $1}')
kubectl exec --stdin --tty -n bamoe-k8s ${KC_POD} -- /bin/bash

cat /opt/keycloak/data/import/custom-realm.json


#------------------------------------------------------------

kubectl delete pv postgres-bamoe-pv


#--------------------------------

# host minikube
http://192.168.49.2:45200
pgadmin console: admin@example.com / admin
minikube service -n bamoe-k8s pgadmin --url
  

postgresdb: postgres / myPgPassword


kubectl exec --stdin --tty -n bamoe-k8s pgadmin-cb8f795d9-8tbcl -- /bin/bash

# da pod postgres

```

# RIVEDERE
https://blog.brakmic.com/keycloak-with-postgresql-on-kubernetes/

https://docs.redhat.com/en/documentation/red_hat_build_of_keycloak/22.0/html/operator_guide/basic-deployment-#basic-deployment-tls-certificate-and-key


# log-commands

# Set env vars
```
# K8S
source ./env.properties

# OCP
source ./env-ocp.properties
```

## Postgres
```
POSTGRES_POD=$(kubectl get pods -n ${_NS} --no-headers | grep postgres | awk '{print $1}')

# follow log
kubectl logs -f -n ${_NS} ${POSTGRES_POD}

# enter default container shell
kubectl exec --stdin --tty -n ${_NS} ${POSTGRES_POD} -- /bin/bash

# from inside pod login to PG server
PGPASSWORD=myPgPassword psql -h localhost -p 5432 -U postgres
```


## PGAdmin
```
PGADMIN_POD=$(kubectl get pods -n ${_NS} --no-headers | grep pgadmin | awk '{print $1}')

# follow log
kubectl logs -f -n ${_NS} ${PGADMIN_POD}

# enter default container shell
kubectl exec --stdin --tty -n ${_NS} ${PGADMIN_POD} -- /bin/bash
```


## Keycloak
```
KC_POD=$(kubectl get pods -n ${_NS} --no-headers | grep keycloak | awk '{print $1}')

# follow log
kubectl logs -f -n ${_NS} ${KC_POD}

# enter default container shell
kubectl exec --stdin --tty -n ${_NS} ${KC_POD} -- /bin/bash
```


## BAMOE
```
BAMOE_POD=$(kubectl get pods -n ${_NS} --no-headers | grep bamoe | awk '{print $1}')

# follow log of backend container
kubectl logs -f -c backend -n ${_NS} ${BAMOE_POD}

# follow log of frontend container
kubectl logs -f -c frontend -n ${_NS} ${BAMOE_POD}

# enter frontend container shell
kubectl exec --stdin --tty -c frontend -n ${_NS} ${BAMOE_POD} -- /bin/bash

# enter backend container shell
kubectl exec --stdin --tty -c backend -n ${_NS} ${BAMOE_POD} -- /bin/bash
```


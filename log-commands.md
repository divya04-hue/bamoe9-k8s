# log-commands

## Postgres
```
POSTGRES_POD=$(kubectl get pods -n bamoe-k8s --no-headers | grep postgres | awk '{print $1}')

# follow log
kubectl logs -f -n bamoe-k8s ${POSTGRES_POD}

# enter default container shell
kubectl exec --stdin --tty -n bamoe-k8s ${POSTGRES_POD} -- /bin/bash

# from inside pod login to PG server
PGPASSWORD=myPgPassword psql -h localhost -p 5432 -U postgres
```


## PGAdmin
```
PGADMIN_POD=$(kubectl get pods -n bamoe-k8s --no-headers | grep pgadmin | awk '{print $1}')

# follow log
kubectl logs -f -n bamoe-k8s ${PGADMIN_POD}

# enter default container shell
kubectl exec --stdin --tty -n bamoe-k8s ${PGADMIN_POD} -- /bin/bash
```


## Keycloak
```
KC_POD=$(kubectl get pods -n bamoe-k8s --no-headers | grep keycloak | awk '{print $1}')

# follow log
kubectl logs -f -n bamoe-k8s ${KC_POD}

# enter default container shell
kubectl exec --stdin --tty -n bamoe-k8s ${KC_POD} -- /bin/bash
```


## BAMOE
```
BAMOE_POD=$(kubectl get pods -n bamoe-k8s --no-headers | grep bamoe | awk '{print $1}')

# follow log of backend container
kubectl logs -f -c backend -n bamoe-k8s ${BAMOE_POD}

# follow log of frontend container
kubectl logs -f -c frontend -n bamoe-k8s ${BAMOE_POD}

# enter frontend container shell
kubectl exec --stdin --tty -c frontend -n bamoe-k8s ${BAMOE_POD} -- /bin/bash

# enter backend container shell
kubectl exec --stdin --tty -c backend -n bamoe-k8s ${BAMOE_POD} -- /bin/bash
```


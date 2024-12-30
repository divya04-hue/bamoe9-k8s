# log-commands

## Postgres
```
POSTGRES_POD=$(kubectl get pods -n bamoe-k8s --no-headers | grep postgres | awk '{print $1}')

kubectl logs -f -n bamoe-k8s ${POSTGRES_POD}

kubectl exec --stdin --tty -n bamoe-k8s ${POSTGRES_POD} -- /bin/bash

PGPASSWORD=myPgPassword psql -h localhost -p 5432 -U postgres
```


## PGAdmin
```
PGADMIN_POD=$(kubectl get pods -n bamoe-k8s --no-headers | grep pgadmin | awk '{print $1}')

kubectl logs -f -n bamoe-k8s ${PGADMIN_POD}

kubectl exec --stdin --tty -n bamoe-k8s ${PGADMIN_POD} -- /bin/bash
```



## Keycloak
```
KC_POD=$(kubectl get pods -n bamoe-k8s --no-headers | grep keycloak | awk '{print $1}')

kubectl logs -f -n bamoe-k8s ${KC_POD}

kubectl exec --stdin --tty -n bamoe-k8s ${KC_POD} -- /bin/bash
```

## BAMOE
```
BAMOE_POD=$(kubectl get pods -n bamoe-k8s --no-headers | grep bamoe | awk '{print $1}')

kubectl logs -f -c backend -n bamoe-k8s ${BAMOE_POD}

kubectl logs -f -c frontend -n bamoe-k8s ${BAMOE_POD}

kubectl exec --stdin --tty -c frontend -n bamoe-k8s ${BAMOE_POD} -- /bin/bash

kubectl exec --stdin --tty -c backend -n bamoe-k8s ${BAMOE_POD} -- /bin/bash
```


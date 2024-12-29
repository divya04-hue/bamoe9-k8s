# bamoe9-k8s

## Introduzione

## Scenario

## Sistemi utilizzati

## Applicazioni utilizzate

## Container e registry

## Ambiente target per deployment

## Configurazione delle CR

### Struttura del repository
<pre>
./k8s-CRs
./k8s-CRs/bamoe
./k8s-CRs/postgres
./k8s-CRs/pgadmin
./k8s-CRs/keycloak
</pre>

## Deployment delle CR

## Verifiche

## Run istanze di processo

## Conclusioni


## TBD
#------------------------------------------------------------


# host minikube
http://192.168.49.2:45200
pgadmin console: admin@example.com / admin
minikube service -n bamoe-k8s pgadmin --url
  

postgresdb: postgres / myPgPassword


kubectl exec --stdin --tty -n bamoe-k8s pgadmin-cb8f795d9-8tbcl -- /bin/bash

# da pod postgres

```

## Template variables for pod/depl configuration
```
#!/bin/bash
PROPERTIES_FILE=./src/main/resources/application.properties
if [[ -f ${PROPERTIES_FILE} ]]; then
  cat ${PROPERTIES_FILE} \
    | sed 's/=.*//g' \
    | sed 's/^%.*//g' \
    | sed 's/^#.*//g' \
    | sed '/^$/d' \
    | sed 's/-/_/g' \
    | sed 's/\//_/g' \
    | sed 's/\./_/g' \
    | sed 's/[a-z]/\U&/g' \
    | sed 's/^/            - name: /g' \
    | sort
fi
```


# Refs
https://blog.brakmic.com/keycloak-with-postgresql-on-kubernetes/

https://docs.redhat.com/en/documentation/red_hat_build_of_keycloak/22.0/html/operator_guide/basic-deployment-#basic-deployment-tls-certificate-and-key


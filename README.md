# bamoe9-k8s

## Introduction

This repository contains an example of a 'complete deployment' in a Kubernetes environment for an application based on a BPMN process in IBM BAMOE runtime version 9.1.1 (technical preview for long running processes supported by a database), the application is based on Quarkus technology.

The contents of this repository must be understood as an example of architecture and functional integration in a Kubernetes environment; they are not suitable for reuse in production environments.
As you can see, security enforcements are practically absent or minimal and present (user roles enforcement) for demonstration purposes only.

Minikube environment has been selected as a deployment target environment to demonstrate the simplicity of setup even on the developer's desktop.


## Scenario

The use case involves the use of a simple application based on a BPMN process implemented with two human tasks profiled for two different organizational roles.

Users who interact with the application must be authenticated and provide in each interaction with the application a set of credentials identified by a JWT token obtained through a login operation to an OIDC server (in this scenario Keycloak).

Keycloak has been configured with a customized realm for which two user groups have been created, one for Human Resources users, the other for Information Technology users; two roles 'HR' and 'IT' have been created to which the two user groups have been associated. What is defined as 'Realm Role' in Keycloak corresponds to the configuration in the 'Group' section of the human tasks.

With this configuration the human tasks of the process will be visible and usable only by users profiled for the role associated with the human task.

The database server supporting the solution is set up for two databases, one to support the BAMOE process runtime, the other to support the Keycloak server.

To create effective security enforcement, the BPM application was protected with a specific http policy.

A simple application was created that stands between the client and the BPM process application and that implements authentication and authorization enforcement based on JWT tokens; this application dynamically extracts the roles associated with the user from the JWT token and readjusts the call to the BPM application that can only be reached on address 127.0.0.1 within the execution pod; in this way the frontend container protects the backend application by appropriately implementing the 'Sidecar' pattern.

The frontend application also implements authorization logic that is not present in the standard BPMN notation such as which roles can start new process instances.

The frontend application is intended to be an example from which to take inspiration and create your own access security policies for BPMN applications created with Kogito technology (current version in the 'incubator' phase, https://github.com/orgs/apache/repositories?q=kogito), in this case on IBM BAMOE distribution version 9.1.1


## Systems used

A 'complete deployment' is a set of components such as:
1. Postgresql database
2. PGAdmin for database administration
3. Keycloak for SSO security management with JWT token
4. BAMOE in Compact architecture

## Applications used

The source code repo for BPM application https://github.com/marcoantonioni/bamoe9-oidc-processes

Of course I invite you to make a clone and modify everything to your needs.

## Containers and registries

Containers ready to use can be pulled from my quay.io account

https://quay.io/repository/marco_antonioni/bamoe9-compact-architecture-security
https://quay.io/repository/marco_antonioni/bamoe9-process-jwt-security


## Target environment for deployment

As mentioned above I chose Minikube (https://minikube.sigs.k8s.io/docs/) because it is a solid K8S environment and well known by many. 

The CRs that you will find in this repository are generic and can be deployed in any K8S and Openshift runtime, obviously also Openshift Local (https://developers.redhat.com/products/openshift-local/overview).


## CR configuration

In the 'k8s-CRs' folder there are all the CRs in yaml format ready to be deployed in the 'bamoe-k8s' namespace; modify them as you like.

In the 'configuration/configuration-steps.md' file you will find a series of snippets for the creation of the various CRs starting from a series of environment variables defined in the 'env.properties' file.

<b>Warning</b>:
<mark>
Authentication and verification of the validity of the JWT token require (frontend policy) among other things that the token has been created from a specific URL that has been configured in the environment variable of the frontend container (QUARKUS_OIDC_AUTH_SERVER_URL and QUARKUS_OIDC_CLIENT_AUTH_SERVER_URL).
In order to be authorized you will have to configure (even simply on the '/etc/hosts' file) an entry with the name 'minikube' and the IP address of your Minikube runtime. To obtain the IP of the Minikube instance, execute the command 'minikube ip'.
The same goes for the port number assigned to the 'nodePort' of the various 'Service'; adapt them according to your needs.
</mark>

## CR Deployment / Undeployment

The shell scripts 'deploy-all-resources.sh' and 'undeploy-all-resources.sh' are available to automate the deployment of the scenario.

The deployment involves the use of a single namespace within which the various components will operate.

The networking addressing between the various components uses only the name of the relative 'Service' and therefore is resolved within the namespace subnet.


## Verifications

Al termine del deployment potete fare alcune verifiche di base.
Non allarmatevi se qualche pod segnalerà uno o più restart, probabilmente sarà a causa dei tempi di setup del database Postgres.

1. Verifica del setup di Postgres e dei database 'keycloak' e 'bamoe'

2. Verifica della configurazione del realm custom in Keycloak

3. Verifica del corretto deployment della applicazione di processo 'hiring'


## Run Process Instances

## Conclusions

## References


## TBD
#------------------------------------------------------------


# host minikube
http://minikube
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


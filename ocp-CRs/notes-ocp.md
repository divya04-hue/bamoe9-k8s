
# PGAdmin
```
cat <<EOF > ./ocp-CRs/pgadmin/scc.yaml
kind: SecurityContextConstraints
apiVersion: security.openshift.io/v1
metadata:
  name: scc-pga
allowPrivilegedContainer: false
runAsUser:
  type: MustRunAsRange
  uidRangeMin: 5000
  uidRangeMax: 6000
seLinuxContext:
  type: RunAsAny
fsGroup:
  type: MustRunAs
  ranges:
  - min: 5000
    max: 6000
supplementalGroups:
  type: MustRunAs
  ranges:
  - min: 5000
    max: 6000
EOF
```

```
cat <<EOF > ./ocp-CRs/pgadmin/roles.yaml
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: role-pga
rules:
  - apiGroups: ["security.openshift.io"]
    resources: ["securitycontextconstraints"]
    resourceNames: ["scc-pga"]
    verbs: ["use"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: role-binding-pga
subjects:
  - kind: ServiceAccount
    name: sa-pga
roleRef:
  kind: Role
  name: role-pga
  apiGroup: rbac.authorization.k8s.io
EOF
```

```
cat <<EOF > ./ocp-CRs/pgadmin/route.yaml
kind: Route
apiVersion: route.openshift.io/v1
metadata:
  name: pgadmin
  namespace: bamoe-ns
  labels:
    app: pgadmin
spec:
  path: /
  to:
    kind: Service
    name: pgadmin
    weight: 100
  port:
    targetPort: 80
  tls:
    termination: edge
  wildcardPolicy: None
EOF
```

# Keycloak

```
cat <<EOF > ./ocp-CRs/keycloak/route.yaml
kind: Route
apiVersion: route.openshift.io/v1
metadata:
  name: keycloak
  namespace: bamoe-ns
  labels:
    app: keycloak
spec:
  path: /
  to:
    kind: Service
    name: keycloak
    weight: 100
  port:
    targetPort: 8080
  tls:
    termination: edge
  wildcardPolicy: None
EOF
```

```
source ./env-ocp.properties

kubectl apply -f ./${_FOLDER}/bamoe-ns.yaml 

kubectl apply -f ./${_FOLDER}/postgres/${_CR_NAME_SECR_PWD_POSTGRES}.yaml 
kubectl apply --validate=false -f ./${_FOLDER}/postgres/postgres.yaml

oc adm policy add-scc-to-group anyuid system:serviceaccounts:bamoe-ns
oc create -f ./ocp-CRs/pgadmin/scc.yaml -n bamoe-ns
oc create -f ./ocp-CRs/pgadmin/roles.yaml -n bamoe-ns
oc create sa sa-pga -n bamoe-ns

oc create configmap -n ${_NS} pgadmin-config --from-file=servers.json=./${_FOLDER}/pgadmin/servers.json
oc create configmap -n ${_NS} pgadmin-passwd --from-file=my-passwords.pgpass=./${_FOLDER}/pgadmin/my-passwords.pgpass

oc apply -f ./ocp-CRs/pgadmin/pgadmin.yaml
oc apply -f ./ocp-CRs/pgadmin/route.yaml

oc create configmap -n ${_NS} ${_REALM_NAME} --from-file=${_REALM_NAME}.json=./${_FOLDER}/keycloak/custom-realm.json 
oc apply -f ./${_FOLDER}/keycloak/${_CR_NAME_DEP_KC}.yaml 
oc apply -f ./${_FOLDER}/keycloak/route.yaml
```


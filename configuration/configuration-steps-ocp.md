
# Configuration steps to deploy into OCP

Following snippets are used to generate CRs for various components.

Before run any command set all variables in shell env.

## Environment variables
```
source ./env-ocp.properties
```

## namespace
```
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
```

#--------------------------
## storage

```
cat <<EOF > ./${_FOLDER}/postgres/${_CR_NAME_PVC}.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${_CR_NAME_PVC}
  namespace: ${_NS}
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: managed-nfs-storage
  resources:
    requests:
      storage: 5Gi
EOF
```

## Postgres

#### Deployment 

```
cat <<EOF > ./${_FOLDER}/postgres/${_CR_NAME_DEP_POSTGRES}.yaml
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
      port: ${_CR_NAME_DEP_POSTGRES_PORT}
      targetPort: ${_CR_NAME_DEP_POSTGRES_PORT}
---
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
            - containerPort: ${_CR_NAME_DEP_POSTGRES_PORT}
          env:
            - name: POSTGRES_PASSWORD
              value: ${_PG_PWD}
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
EOF
```

### INIT.SQL
```
cat <<EOF > ./${_FOLDER}/postgres/${_INIT_DB_FILE}
CREATE ROLE "${_BAMOE_DB_USER}" WITH
    LOGIN
    SUPERUSER
    INHERIT
    CREATEDB
    CREATEROLE
    NOREPLICATION
    PASSWORD '${_BAMOE_DB_PASS}';

CREATE DATABASE bamoedb
    WITH
    OWNER = "${_BAMOE_DB_USER}"
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.utf8'
    LC_CTYPE = 'en_US.utf8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

CREATE DATABASE keycloak
    WITH
    OWNER = "${_BAMOE_DB_USER}"
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.utf8'
    LC_CTYPE = 'en_US.utf8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

GRANT ALL PRIVILEGES ON DATABASE postgres TO "${_BAMOE_DB_USER}";

GRANT ALL PRIVILEGES ON DATABASE bamoedb TO "${_BAMOE_DB_USER}";
GRANT ALL PRIVILEGES ON DATABASE bamoedb TO postgres;

GRANT ALL PRIVILEGES ON DATABASE keycloak TO "${_BAMOE_DB_USER}";
GRANT ALL PRIVILEGES ON DATABASE keycloak TO postgres;
EOF
```

## PGADMIN

### Servers
```
cat <<EOF > ./${_FOLDER}/pgadmin/servers.json
{
  "Servers": {
    "1": {
      "Name": "my-databases",
      "Group": "Servers",
      "Host": "${_CR_NAME_DEP_POSTGRES}",
      "Port": ${_CR_NAME_DEP_POSTGRES_PORT},
      "MaintenanceDB": "postgres",
      "Username": "${_PG_USER}",
      "UseSSHTunnel": 0,
      "TunnelPort": "22",
      "TunnelAuthentication": 0,
      "KerberosAuthentication": false,
      "ConnectionParameters": {
        "sslmode": "disable",
        "passfile": "/pgadmin4/mypasswords/my-passwords.pgpass"
      }
    }
  }
}
EOF
```

### pgpass
```
cat <<EOF > ./${_FOLDER}/pgadmin/my-passwords.pgpass
${_CR_NAME_DEP_POSTGRES}:${_CR_NAME_DEP_POSTGRES_PORT}:postgres:${_PG_USER}:${_PG_PWD}
${_CR_NAME_DEP_POSTGRES}:${_CR_NAME_DEP_POSTGRES_PORT}:keycloak:${_PG_USER}:${_PG_PWD}
${_CR_NAME_DEP_POSTGRES}:${_CR_NAME_DEP_POSTGRES_PORT}:bamoedb:${_PG_USER}:${_PG_PWD}
EOF
```

### Deployment
```
cat <<EOF > ./${_FOLDER}/pgadmin/${_CR_NAME_DEP_PGADMIN}.yaml
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
    - nodePort: ${_PGADMIN_NODE_PORT}
      port: 80
      targetPort: 80
---
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
          image: 'dpage/pgadmin4:latest'
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
              value: "/pgadmin4/mypasswords/my-passwords.pgpass"
          ports:
            - containerPort: 80
              name: pgadminport
          volumeMounts:
            - name: pgadmin-config
              mountPath: /pgadmin4/myconfig
            - name: pgadmin-passwd
              mountPath: /pgadmin4/mypasswords
      volumes:
        - name: pgadmin-config
          configMap:
            name: pgadmin-config       
        - name: pgadmin-passwd
          configMap:
            name: pgadmin-passwd       
EOF
```

## Keycloak
```
cat <<EOF > ./${_FOLDER}/keycloak/${_CR_NAME_DEP_KC}.yaml
apiVersion: v1
kind: Service
metadata:
  name: ${_CR_NAME_DEP_KC}
  namespace: ${_NS}
  labels:
    app: ${_CR_NAME_DEP_KC}
spec:
  selector:
    app: ${_CR_NAME_DEP_KC}
  type: NodePort
  ports:
    - nodePort: ${_KC_NODE_PORT}
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
              value: jdbc:postgresql://${_CR_NAME_DEP_POSTGRES}:${_CR_NAME_DEP_POSTGRES_PORT}/keycloak
            - name: KC_DB_USERNAME
              value: ${_PG_USER}
            - name: KC_DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: ${_CR_NAME_SECR_PWD_POSTGRES}
                  key: password            
          volumeMounts:
            - name: realm-config
              mountPath: /opt/keycloak/data/import
      volumes:
        - name: realm-config
          configMap:
            name: ${_REALM_NAME}
EOF
```

## BAMOE application
```
cat <<EOF > ./${_FOLDER}/bamoe/${_CR_NAME_DEP_BAMOE}.yaml
apiVersion: v1
kind: Service
metadata:
  name: ${_CR_NAME_DEP_BAMOE}
  namespace: ${_NS}
  labels:
    app: ${_CR_NAME_DEP_BAMOE}
spec:
  selector:
    app: ${_CR_NAME_DEP_BAMOE}
  type: NodePort
  ports:
    - name: backend
      nodePort: ${_BAMOE_BACKEND_NODE_PORT}
      port: 8080
      targetPort: 8080
    - name: frontend
      nodePort: ${_BAMOE_FRONTEND_NODE_PORT}
      port: 8880
      targetPort: 8880
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${_CR_NAME_DEP_BAMOE}
  namespace: ${_NS}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${_CR_NAME_DEP_BAMOE}
  template:
    metadata:
      labels:
        app: ${_CR_NAME_DEP_BAMOE}
    spec:
      containers:
        - name: backend
          image: quay.io/marco_antonioni/bamoe9-compact-architecture-security:1.0.0
          env:
            - name: KOGITO_DATA_INDEX_URL
              value: 'http://0.0.0.0:8080'
            - name: KOGITO_JOBS_SERVICE_URL
              value: 'http://0.0.0.0:8080'
            - name: KOGITO_PERSISTENCE_TYPE
              value: jdbc
            - name: KOGITO_SERVICE_URL
              value: 'http://0.0.0.0:8080'
            - name: QUARKUS_DATASOURCE_DB_KIND
              value: postgresql
            - name: QUARKUS_FLYWAY_BASELINE_ON_MIGRATE
              value: 'true'
            - name: QUARKUS_FLYWAY_BASELINE_VERSION
              value: '0.0'
            - name: QUARKUS_FLYWAY_LOCATIONS
              value: 'classpath:/db/migration,classpath:/db/jobs-service,classpath:/db/data-audit/postgresql'
            - name: QUARKUS_FLYWAY_MIGRATE_AT_START
              value: 'true'
            - name: QUARKUS_FLYWAY_TABLE
              value: 'FLYWAY_RUNTIME_SERVICE'
            - name: QUARKUS_HTTP_AUTH_PERMISSION_BACKEND_OIDC_CLIENT_ID
              value: 'my-client-bpm'
            - name: QUARKUS_HTTP_AUTH_PERMISSION_BACKEND_OIDC_CLIENT_SCOPE
              value: 'my-bpm-scope'
            - name: QUARKUS_HTTP_AUTH_PERMISSION_BACKEND_PATHS
              value: '/hiring/*,/graphql'
            - name: QUARKUS_HTTP_AUTH_PERMISSION_BACKEND_POLICY
              value: 'mybackendsecpolicy'
            - name: QUARKUS_HTTP_AUTH_PERMISSION_BACKEND_VALIDATE_ONLY_AUTHENTICATED
              value: 'true'
            - name: QUARKUS_HTTP_AUTH_PERMISSION_BACKEND_VALIDATE_ONLY_LOCALHOST
              value: 'true'
            - name: QUARKUS_HTTP_AUTH_PERMISSION_BACKEND_VALIDATE_SERVICE_HEADER
              value: 'true'
            - name: QUARKUS_HTTP_CORS
              value: 'true'
            - name: QUARKUS_HTTP_CORS_ORIGINS
              value: '*'
            - name: QUARKUS_KOGITO_DATA_INDEX_GRAPHQL_UI_ALWAYS_INCLUDE
              value: 'true'
            - name: QUARKUS_KOGITO_DEVSERVICES_ENABLED
              value: 'false'
            - name: QUARKUS_LOG_LEVEL
              value: 'INFO'
            - name: QUARKUS_OIDC_ENABLED
              value: 'false'
            - name: QUARKUS_SMALLRYE_OPENAPI_PATH
              value: '/docs/openapi.json'
            - name: QUARKUS_SWAGGER_UI_ALWAYS_INCLUDE
              value: 'false'
            - name: QUARKUS_DATASOURCE_JDBC_URL
              value: ${_QUARKUS_DS_JDBC_URL}
            - name: QUARKUS_DATASOURCE_REACTIVE_URL
              value: ${_QUARKUS_DS_REACTIVE_URL}
            - name: QUARKUS_DATASOURCE_USERNAME
              value: ${_BAMOE_DB_USER}
            - name: QUARKUS_DATASOURCE_PASSWORD
              value: ${_BAMOE_DB_PASS}
        - name: frontend
          image: quay.io/marco_antonioni/bamoe9-process-jwt-security:1.0.0
          env:
            - name: MARCO_BAMOE_PROCESS_STARTER_ROLES_HIRING
              value: 'HR'
            - name: MARCO_BAMOE_PROCESS_VIEWER_ROLES
              value: 'HR'
            - name: MARCO_STUDIO_CACHE_NAME
              value: 'myServiceId'
            - name: MARCO_STUDIO_RESTCLIENT_MYBAMOERESTCLIENT_MP_REST_URL
              value: 'http://localhost:8080'
            - name: MARCO_STUDIO_VALIDATE_TOKEN_SCOPE
              value: 'my-bpm-scope'
            - name: QUARKUS_CACHE_CAFFEINE_MYSERVICEID_EXPIRE_AFTER_WRITE
              value: '10S'
            - name: QUARKUS_CACHE_CAFFEINE_MYSERVICEID_INITIAL_CAPACITY
              value: '100'
            - name: QUARKUS_CACHE_CAFFEINE_MYSERVICEID_MAXIMUM_SIZE
              value: '1000'
            - name: QUARKUS_HTTP_AUTH_PERMISSION_BAMOE_PATHS
              value: '/bamoe/*'
            - name: QUARKUS_HTTP_AUTH_PERMISSION_BAMOE_POLICY
              value: 'myfrontendsecpolicy'
            - name: QUARKUS_HTTP_HOST
              value: '0.0.0.0'
            - name: QUARKUS_HTTP_PORT
              value: '8880'
            - name: QUARKUS_LOG_LEVEL
              value: 'INFO'
            - name: QUARKUS_OIDC_AUTH_SERVER_URL
              value: '${_OIDC_REALM_URL}'
            - name: QUARKUS_OIDC_CLIENT_AUTH_SERVER_URL
              value: '${_OIDC_REALM_URL}'
            - name: QUARKUS_OIDC_CLIENT_CLIENT_ID
              value: 'my-client-bpm'
            - name: QUARKUS_OIDC_CLIENT_CREDENTIALS_SECRET
              value: 'my-secret-bpm'
            - name: QUARKUS_OIDC_CLIENT_ID
              value: 'my-client-bpm'
            - name: QUARKUS_OIDC_CREDENTIALS_SECRET
              value: 'my-secret-bpm'
            - name: QUARKUS_SMALLRYE_OPENAPI_PATH
              value: '/docs/openapi.json'
            - name: QUARKUS_SWAGGER_UI_ALWAYS_INCLUDE
              value: 'true'
EOF
```




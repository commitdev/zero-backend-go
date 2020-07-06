apiVersion: v1
kind: Namespace
metadata:
  name: db-ops
---
apiVersion: v1
kind: Secret
metadata:
  name: db-create-users
  namespace: db-ops
type: Opaque
stringData: 
  create-user.sql: |
    create user $DB_APP_USERNAME with encrypted password '$DB_APP_PASSWORD';
    grant all privileges on database $PROJECT_NAME to $DB_APP_USERNAME;
  RDS_MASTER_PASSWORD: $SECRET_PASSWORD
---
apiVersion: v1
kind: Secret
metadata:
  name: $PROJECT_NAME
  namespace: $PROJECT_NAME
type: Opaque
stringData: 
  DB_USERNAME: $DB_APP_USERNAME
  DB_PASSWORD: $DB_APP_PASSWORD
---
apiVersion: batch/v1
kind: Job
metadata:
  name: db-create-users
  namespace: db-ops
spec:
  template:
    spec:
      containers:
      - name: create-rds-user
        image: $DOCKER_IMAGE_TAG
        command: 
        - sh
        args: 
        - '-c' 
        - psql -U$MASTER_RDS_USERNAME -h $DB_ENDPOINT $PROJECT_NAME -a -f/db-ops/create-user.sql > /dev/null
        env:
        - name: PGPASSWORD
          valueFrom:
            secretKeyRef:
              name: db-create-users
              key: RDS_MASTER_PASSWORD
        volumeMounts:
        - mountPath: /db-ops/create-user.sql
          name: db-create-users
          subPath: create-user.sql
      volumes:
        - name: db-create-users
          secret:
            secretName: db-create-users
      restartPolicy: Never
  backoffLimit: 1

#!/bin/sh

# docker image with postgres client only
DOCKER_IMAGE_TAG=governmentpaas/psql:latest

DB_ENDPOINT=$(aws rds describe-db-instances --region=$REGION --query "DBInstances[?DBName=='$PROJECT_NAME'].Endpoint.Address" | jq -r '.[0]')
SECRET_ID=$(aws secretsmanager list-secrets --region $REGION  --query "SecretList[?Name=='$PROJECT_NAME-$ENVIRONMENT-rds-$SEED'].Name" | jq -r ".[0]")
# RDS MASTER
MASTER_RDS_USERNAME=master_user
SECRET_PASSWORD=$(aws secretsmanager get-secret-value --region=$REGION --secret-id=$SECRET_ID | jq -r ".SecretString")
# APPLICATION DB ADMIN
DB_APP_USERNAME=$PROJECT_NAME
DB_APP_PASSWORD=$(LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | base64 | head -c 16)

# Fill in env-vars to db user creation manifest
eval "echo \"$(cat ./db-ops/job-create-db.yml.tpl)\"" > ./k8s-job-create-db.yml
# the manifest creates 4 things
# 1. Namespace: db-ops 
# 2. Secret in db-ops: db-create-users (with master password, and a .sql file
# 3. Job in db-ops: db-create-users (runs the .sql file against the RDS given master_password from env)
# 4. Secret in Application namespace with DB_USERNAME / DB_PASSWORD 
kubectl create -f ./k8s-job-create-db.yml

# Deleting the entire db-ops namespace, leaving ONLY application-namespace's secret behind
kubectl -n db-ops wait --for=condition=complete --timeout=10s job db-create-users
if [ $? -eq 0 ]
then 
  kubectl delete namespace db-ops
else 
  echo "Failed to create application database user, please see 'kubectl logs -n db-ops -l job-name=db-create-users'"
fi

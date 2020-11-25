#!/bin/bash

#
# This script is to create a dev namespace on Staging environment
#
PROJECT_NAME=<% .Name %>
ENVIRONMENT=stage

# common functions
function usage() {
    echo
    echo "Usage:"
    echo "  $0 <IAM user> <project id>"
    echo "    - IAM user: can be found by running 'aws iam get-group --group-name ${PROJECT_NAME}-developer-${ENVIRONMENT} | jq -r .Users[].UserName'"
    exit 1
}

function command_exist() {
    command -v ${1} >& /dev/null
}

function error_exit() {
    echo "ERROR : $1"
    exit 2
}

function can_i() {
    command=$1
    kubectl auth can-i $1 >& /dev/null || error_exit "No permission to $1"
}

# Start
USER_NAME=$1
DEV_PROJECT_ID=$2
[[ -z "$USER_NAME" ]] && usage
[[ -z "$DEV_PROJECT_ID" ]] && DEV_PROJECT_ID="001"

# Check installation: skaffold & telepresence
if ! command_exist skaffold || ! command_exist telepresence; then
    if ! command_exist skaffold; then
        error_exit "command 'skaffold' not found: please visit https://skaffold.dev/docs/install/"
    fi
    if ! command_exist kubectl; then
        error_exit "command 'telepresence' not found. You can download it at https://www.telepresence.io/reference/install."
    fi
fi

# Validate input
NAMESPACE=${PROJECT_NAME}
SECRET_NAME=${PROJECT_NAME}
DEV_SECRET_NAME=dev-${USER_NAME}
DEV_SECRET_JSON=$(kubectl get secret ${DEV_SECRET_NAME} -n ${NAMESPACE} -o json)
[[ -z "${DEV_SECRET_JSON}" ]] && error_exit "The secret ${DEV_SECRET_NAME} is not existing. Please check secrets with 'kubectl get secrets'"

# Setup dev namepsace
DEV_USER_PROJECT=${USER_NAME}-${DEV_PROJECT_ID}
DEV_NAMESPACE=${DEV_USER_PROJECT}
kubectl get namespace ${DEV_NAMESPACE} >& /dev/null || \
    (can_i "create namespace" && kubectl create namespace ${DEV_NAMESPACE} && \
    can_i "create deployment -n ${DEV_NAMESPACE}" && \
    can_i "create ingress -n ${DEV_NAMESPACE}" && \
    can_i "create service -n ${DEV_NAMESPACE}" && \
    can_i "create configmaps -n ${DEV_NAMESPACE}")
echo "Namespace: ${DEV_NAMESPACE}"

# Setup dev secret from pre-configed one
kubectl get secret ${SECRET_NAME} -n ${DEV_NAMESPACE} >& /dev/null || \
    echo ${DEV_SECRET_JSON} | jq 'del(.metadata["namespace","creationTimestamp","resourceVersion","selfLink","uid"])' | sed "s/${DEV_SECRET_NAME}/${SECRET_NAME}/g" | kubectl apply -n ${DEV_NAMESPACE} -f -
echo "Secret: ${SECRET_NAME}"

# Setup dev service account from pre-configured one
SERVICE_ACCOUNT=backend-service
kubectl get sa ${SERVICE_ACCOUNT} -n ${DEV_NAMESPACE} >& /dev/null || \
    kubectl get sa ${SERVICE_ACCOUNT} -n ${NAMESPACE} -o json | jq 'del(.metadata["namespace","creationTimestamp","resourceVersion","selfLink","uid"])' | kubectl apply -n ${DEV_NAMESPACE} -f -
echo "Service Account: ${SERVICE_ACCOUNT}"

# Prepare varaibles
ACCOUNT_ID=<% index .Params `accountId` %>
REGION=<% index .Params `region` %>
CLUSTER=${PROJECT_NAME}-stage-${REGION}
DEPLOYMENT=${PROJECT_NAME}
REPO=${PROJECT_NAME}
EXT_HOSTNAME=<% index .Params `stagingBackendSubdomain`  %><% index .Params `stagingHostRoot` %>
MY_EXT_HOSTNAME=${DEV_USER_PROJECT}-${EXT_HOSTNAME}
ECR_REPO=${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO}
VERSION_TAG=lastest-${USER_NAME}
DATABASE_NAME=<% index .Params `databaseName` %>
DEV_DATABASE_NAME=$(echo "dev-${USER_NAME}" | tr -dc 'A-Za-z0-9')

CONFIG_ENVIRONMENT="staging"

# Setup dev k8s manifests
cp -pr kubernetes kubernetes.tmp
echo "start manifest changes"
## image: set image definition
sed -i ".bak" "s|image: fake-image|image: ${ECR_REPO}:${VERSION_TAG}|g" kubernetes.tmp/base/deployment.yml
## ingress: create new domain with external DNS
sed -i ".bak" "s|${EXT_HOSTNAME}|${MY_EXT_HOSTNAME}|g" kubernetes.tmp/overlays/${CONFIG_ENVIRONMENT}/ingress.yml
## database_name: replace with new one
sed -i ".bak" "s|DATABASE_NAME=${DATABASE_NAME}|DATABASE_NAME=${DEV_DATABASE_NAME}|g" kubernetes.tmp/base/kustomization.yml

# Build & Deploy dev environment with Skaffold
echo
echo "Check backend-service at http://${MY_EXT_HOSTNAME}/"
echo
echo "Intercept the traffic to local by running:"
echo "     telepresence --swap-deployment ${DEPLOYMENT} --namespace ${DEV_NAMESPACE} --expose 80 --run go run main.go"
echo "  or running in docker"
echo "    docker build . -t ${DEPLOYMENT}-dev"
echo "    telepresence --swap-deployment ${DEPLOYMENT} --namespace ${DEV_NAMESPACE} --expose 80 --docker-run --rm -it -v $(pwd):/usr/src/app ${DEPLOYMENT}-dev"
echo

skaffold config set default-repo ${ECR_REPO}
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin ${ECR_REPO} >& /dev/null || error_exit "Failed to login to AWS ECR"
## run in backgound
skaffold run --profile ${CONFIG_ENVIRONMENT} --namespace ${DEV_NAMESPACE}
## run in frontend
#skaffold dev --profile ${CONFIG_ENVIRONMENT} --namespace ${DEV_NAMESPACE}

# Clean up
rm -rf kubernetes.tmp

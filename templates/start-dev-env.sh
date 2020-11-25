#!/bin/bash

#
# This script is to create a dev namespace on Staging environment
#
PROJECT_NAME=<% .Name %>
ENVIRONMENT=stage
ACCOUNT_ID=<% index .Params `accountId` %>
REGION=<% index .Params `region` %>

# common functions
function usage() {
    echo
    echo "Usage:"
    echo "  $0 <IAM user> <project id>"
    echo "    - IAM user: can be found by running 'aws iam get-group --group-name ${PROJECT_NAME}-developer-${ENVIRONMENT} | jq -r .Users[].UserName'"
    echo "    - project id: can be 001, 002, or whatever id without space"
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

echo '[Dev Environment]'

# Validate cluster
CLUSTER=$(kubectl config current-context)
[[ ${CLUSTER} == "${PROJECT_NAME}-${ENVIRONMENT}-${REGION}" ]] || error_exit "Your kubernetes context ${CLUSTER} is not proper to run this script"
echo "  Cluster: ${CLUSTER}"

# Validate secret
NAMESPACE=${PROJECT_NAME}
SECRET_NAME=${PROJECT_NAME}
DEV_SECRET_NAME=dev-${USER_NAME}
DEV_SECRET_JSON=$(kubectl get secret ${DEV_SECRET_NAME} -n ${NAMESPACE} -o json)
[[ -z "${DEV_SECRET_JSON}" ]] && error_exit "The secret ${DEV_SECRET_NAME} is not existing. Please check secrets with 'kubectl get secrets'"

# Check installations
if ! command_exist skaffold || ! command_exist telepresence; then
    if ! command_exist skaffold; then
        error_exit "command 'skaffold' not found: please visit https://skaffold.dev/docs/install/"
    fi
    if ! command_exist kubectl; then
        error_exit "command 'telepresence' not found. You can download it at https://www.telepresence.io/reference/install."
    fi
fi

# Setup dev namepsace
DEV_USER_PROJECT=${USER_NAME}-${DEV_PROJECT_ID}
DEV_NAMESPACE=${DEV_USER_PROJECT}
kubectl get namespace ${DEV_NAMESPACE} >& /dev/null || \
    (can_i "create namespace" && kubectl create namespace ${DEV_NAMESPACE} && \
    can_i "create deployment -n ${DEV_NAMESPACE}" && \
    can_i "create ingress -n ${DEV_NAMESPACE}" && \
    can_i "create service -n ${DEV_NAMESPACE}" && \
    can_i "create secret -n ${DEV_NAMESPACE}" && \
    can_i "create configmap -n ${DEV_NAMESPACE}")
echo "  Namespace: ${DEV_NAMESPACE}"

# Setup dev secret from pre-configed one
kubectl get secret ${SECRET_NAME} -n ${DEV_NAMESPACE} >& /dev/null || \
    echo ${DEV_SECRET_JSON} | jq 'del(.metadata["namespace","creationTimestamp","resourceVersion","selfLink","uid"])' | sed "s/${DEV_SECRET_NAME}/${SECRET_NAME}/g" | kubectl apply -n ${DEV_NAMESPACE} -f -
echo "  Secret: ${SECRET_NAME}"

# Setup dev service account from pre-configured one
SERVICE_ACCOUNT=backend-service
kubectl get sa ${SERVICE_ACCOUNT} -n ${DEV_NAMESPACE} >& /dev/null || \
    kubectl get sa ${SERVICE_ACCOUNT} -n ${NAMESPACE} -o json | jq 'del(.metadata["namespace","creationTimestamp","resourceVersion","selfLink","uid"])' | kubectl apply -n ${DEV_NAMESPACE} -f -

# Setup dev k8s manifests, configuration, docker login etc
CONFIG_ENVIRONMENT="staging"
DEPLOYMENT=${PROJECT_NAME}
REPO=${PROJECT_NAME}
EXT_HOSTNAME=<% index .Params `stagingBackendSubdomain`  %><% index .Params `stagingHostRoot` %>
MY_EXT_HOSTNAME=${DEV_USER_PROJECT}-${EXT_HOSTNAME}
ECR_REPO=${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO}
VERSION_TAG=lastest-${USER_NAME}
DATABASE_NAME=<% index .Params `databaseName` %>
DEV_DATABASE_NAME=$(echo "dev-${USER_NAME}" | tr -dc 'A-Za-z0-9')
rm -rf kubernetes.tmp && cp -pr kubernetes kubernetes.tmp
## image: set image definition
sed -i ".bak" "s|image: fake-image|image: ${ECR_REPO}:${VERSION_TAG}|g" kubernetes.tmp/base/deployment.yml
## ingress: create new domain with external DNS
sed -i ".bak" "s|${EXT_HOSTNAME}|${MY_EXT_HOSTNAME}|g" kubernetes.tmp/overlays/${CONFIG_ENVIRONMENT}/ingress.yml
## database_name: replace with new one
sed -i ".bak" "s|DATABASE_NAME=${DATABASE_NAME}|DATABASE_NAME=${DEV_DATABASE_NAME}|g" kubernetes.tmp/base/kustomization.yml
skaffold config set default-repo ${ECR_REPO} >& /dev/null
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin ${ECR_REPO} >& /dev/null || error_exit "Failed to login to AWS ECR"
echo "  Domain: ${MY_EXT_HOSTNAME}"
echo "  Database Name: ${DEV_DATABASE_NAME}"

echo
echo
echo "Now, you are ready to launch your backend service on Staging under your dev environment/namepsace '${DEV_NAMESPACE}'. This will allow you to debug your cloud backend service on the fly with your local laptop and daily favourite tools like vscode etc."
echo
echo "  Step 1: launch your backend service, run the followings in a terminal:"
echo "    > skaffold run --profile ${CONFIG_ENVIRONMENT} --namespace ${DEV_NAMESPACE}"
echo "    or run in frontend:"
echo "    > skaffold dev --profile ${CONFIG_ENVIRONMENT} --namespace ${DEV_NAMESPACE}"
echo
echo "    to confirm the result:"
echo "    > kubectl -n ${DEV_NAMESPACE} get pods # see pods running"
echo "    > curl http://${MY_EXT_HOSTNAME}/      # see Hello"
echo
echo "  Step 2: intercept the request to local, run the followings in a terminal:"
echo "    > docker build . -t ${DEPLOYMENT}-dev"
echo "    > telepresence --swap-deployment ${DEPLOYMENT} --namespace ${DEV_NAMESPACE} --expose 80 --docker-run --rm -it -v $(pwd):/usr/src/app ${DEPLOYMENT}-dev"
echo "    to confirm the result (in another terminal):"
echo "    > curl http://${MY_EXT_HOSTNAME}/      # see Hello in both terminals"
echo
echo "Then, you can change the code in your editor now, and you will see the live traffic from the browser redirected to your terminal immediately. After confirmed the changes running on Staging, you may just submit it to git repo which will trigger CI/CD workflow as before."
echo
echo "For more detailed information, please refer to:"
echo " telepresence: https://www.telepresence.io/ "
echo " skaffold: https://skaffold.dev/"
echo

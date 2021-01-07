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
    echo "  $0 <project id>"
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
    commands=$1
    IFS=',' read -r -a array <<< "$commands"
    err=0
    for command in "${array[@]}"
    do
        kubectl --context ${CLUSTER_CONTEXT} auth can-i $command >& /dev/null || (echo "No permission to '$command'" && let "err+=1")
    done

    [[ $err -gt 0  ]] && error_exit "Found $err permission errors. Please check with your administrator."

    echo "Permission checks: passed"
    return 0
}

# Start
# Validate current iam user
MY_USERNAME=$(aws sts get-caller-identity --output json | jq -r .Arn | cut -d/ -f2)
DEV_USERS=$(aws iam get-group --group-name ${PROJECT_NAME}-developer-${ENVIRONMENT} | jq -r .Users[].UserName)
[[ "${DEV_USERS[@]}" =~ "${MY_USERNAME}" ]] || error_exit "You (${MY_USERNAME}) are not in the ${PROJECT_NAME}-developer-${ENVIRONMENT} IAM group."

DEV_PROJECT_ID=${1:-""}

echo '[Dev Environment]'

# Validate cluster
CLUSTER_CONTEXT=${PROJECT_NAME}-${ENVIRONMENT}-${REGION}
echo "  Cluster context: ${CLUSTER_CONTEXT}"

# Validate secret
NAMESPACE=${PROJECT_NAME}
SECRET_NAME=${PROJECT_NAME}
DEV_SECRET_NAME=devenv${PROJECT_NAME}
DEV_SECRET_JSON=$(kubectl --context ${CLUSTER_CONTEXT} get secret ${DEV_SECRET_NAME} -n ${NAMESPACE} -o json)
[[ -z "${DEV_SECRET_JSON}" ]] && error_exit "The secret ${DEV_SECRET_NAME} is not existing in namespace '${NAMESPACE}'."

# Check installations
if ! command_exist kustomize || ! command_exist telepresence; then
    if ! command_exist kustomize; then
        error_exit "command 'kustomize' not found: please visit https://kubectl.docs.kubernetes.io/installation/kustomize/"
    fi
    if ! command_exist kubectl; then
        error_exit "command 'telepresence' not found. You can download it at https://www.telepresence.io/reference/install"
    fi
fi

# Setup dev namepsace
DEV_NAMESPACE=${MY_USERNAME}${DEV_PROJECT_ID}
kubectl --context ${CLUSTER_CONTEXT} get namespace ${DEV_NAMESPACE} >& /dev/null || \
    (can_i "create namespace,create deployment,create ingress,create service,create secret,create configmap" && \
    kubectl --context ${CLUSTER_CONTEXT} create namespace ${DEV_NAMESPACE})
echo "  Namespace: ${DEV_NAMESPACE}"

# Setup dev secret from pre-configed one
kubectl --context ${CLUSTER_CONTEXT} get secret ${SECRET_NAME} -n ${DEV_NAMESPACE} >& /dev/null || \
    echo ${DEV_SECRET_JSON} | jq 'del(.metadata["namespace","creationTimestamp","resourceVersion","selfLink","uid"])' | sed "s/${DEV_SECRET_NAME}/${SECRET_NAME}/g" | kubectl --context ${CLUSTER_CONTEXT} apply -n ${DEV_NAMESPACE} -f -
echo "  Secret: ${SECRET_NAME}"

# Setup dev service account from pre-configured one
SERVICE_ACCOUNT=backend-service
kubectl --context ${CLUSTER_CONTEXT} get sa ${SERVICE_ACCOUNT} -n ${DEV_NAMESPACE} >& /dev/null || \
    kubectl --context ${CLUSTER_CONTEXT} get sa ${SERVICE_ACCOUNT} -n ${NAMESPACE} -o json | jq 'del(.metadata["namespace","creationTimestamp","resourceVersion","selfLink","uid"])' | kubectl --context ${CLUSTER_CONTEXT} apply -n ${DEV_NAMESPACE} -f -

# Setup dev k8s manifests, configuration, docker login etc
CONFIG_ENVIRONMENT="dev"
EXT_HOSTNAME=<% index .Params `stagingBackendSubdomain`  %><% index .Params `stagingHostRoot` %>
MY_EXT_HOSTNAME=${DEV_NAMESPACE}-${EXT_HOSTNAME}
ECR_REPO=${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${PROJECT_NAME}
VERSION_TAG=latest
DATABASE_NAME=<% index .Params `databaseName` %>
DEV_DATABASE_NAME=$(echo "dev${MY_USERNAME}" | tr -dc 'A-Za-z0-9')
echo "  Domain: ${MY_EXT_HOSTNAME}"
echo "  Database Name: ${DEV_DATABASE_NAME}"

# Apply migration
MIGRATION_NAME=${PROJECT_NAME}-migration
SQL_DIR="${PWD}/database/migration"
## launch migration job
(cd kubernetes/migration && \
    kubectl --context ${CLUSTER_CONTEXT} -n ${DEV_NAMESPACE} create configmap ${MIGRATION_NAME} --from-file ${SQL_DIR}/*.sql || error_exit "Failed to apply kubernetes migration configmap" && \
    cat job.yml | \
    sed "s|/${DATABASE_NAME}|/${DEV_DATABASE_NAME}|g" | \
    kubectl --context ${CLUSTER_CONTEXT} -n ${DEV_NAMESPACE} create -f - ) || error_exit "Failed to apply kubernetes migration"
## confirm migration job done
if ! kubectl --context ${CLUSTER_CONTEXT} -n ${DEV_NAMESPACE} wait --for=condition=complete --timeout=180s job/${MIGRATION_NAME} ; then
    echo "${MIGRATION_NAME} run failed:"
    kubectl --context ${CLUSTER_CONTEXT} -n ${DEV_NAMESPACE} describe job ${MIGRATION_NAME}
    error_exit "Failed migration. Leaving namespace ${DEV_NAMESPACE} for debugging"
fi

# Apply manifests
(cd kubernetes/overlays/${CONFIG_ENVIRONMENT} && \
    kustomize build . | \
    sed "s|${EXT_HOSTNAME}|${MY_EXT_HOSTNAME}|g" | \
    sed "s|DATABASE_NAME: ${DATABASE_NAME}|DATABASE_NAME: ${DEV_DATABASE_NAME}|g" | \
    kubectl --context ${CLUSTER_CONTEXT} -n ${DEV_NAMESPACE} apply -f - ) || error_exit "Failed to apply kubernetes manifests"

# Confirm deployment
if ! kubectl --context ${CLUSTER_CONTEXT} -n ${DEV_NAMESPACE} rollout status deployment/${PROJECT_NAME} -w --timeout=180s ; then
    echo "${PROJECT_NAME} rollout check failed:"
    echo "${PROJECT_NAME} deployment:"
    kubectl --context ${CLUSTER_CONTEXT} -n ${DEV_NAMESPACE} describe deployment ${PROJECT_NAME}
    echo "${PROJECT_NAME} replicaset:"
    kubectl --context ${CLUSTER_CONTEXT} -n ${DEV_NAMESPACE} describe rs -l app=${PROJECT_NAME}
    echo "${PROJECT_NAME} pods:"
    kubectl --context ${CLUSTER_CONTEXT} -n ${DEV_NAMESPACE} describe pod -l app=${PROJECT_NAME}
    error_exit "Failed deployment. Leaving namespace ${DEV_NAMESPACE} for debugging"
fi

# Verify until the ingress DNS gets ready
echo
if nslookup ${MY_EXT_HOSTNAME} >& /dev/null; then
    echo "  Notice: your domain is ready to use."
else
    echo "  Notice: the first time you use this environment it may take up to 5 minutes for DNS to propagate before the hostname is available."
    bash -c "while ! nslookup ${MY_EXT_HOSTNAME} >& /dev/null; do sleep 30; done; echo && echo \"  Notice: your domain ${MY_EXT_HOSTNAME} is ready to use.\";" &
fi

# Starting telepresence shell
echo
echo "Now you are ready to access your service at:"
echo
echo "  https://${MY_EXT_HOSTNAME}"
echo
echo -n "Your telepresence dev environment is now loading which will proxy all the requests and environment variables from the cloud EKS cluster to the local shell.\nNote that the above URL access will get a \"502 Bad Gateway\" error until you launch the service in the shell, at which point it will start receiving traffic."
echo

# Starting dev environment with telepresence shell
echo
telepresence --context ${CLUSTER_CONTEXT} --swap-deployment ${PROJECT_NAME} --namespace ${DEV_NAMESPACE} --expose 80 --run-shell

# Ending dev environment
## delete the most of resources (except ingress related, as we hit rate limit of certificate issuer(letsencrypt)
echo
kubectl --context ${CLUSTER_CONTEXT} -n ${DEV_NAMESPACE} delete job ${MIGRATION_NAME}
kubectl --context ${CLUSTER_CONTEXT} -n ${DEV_NAMESPACE} delete cm ${MIGRATION_NAME}
for r in hpa deployments services jobs pods cronjob; do
    kubectl --context ${CLUSTER_CONTEXT} -n ${DEV_NAMESPACE} delete $r --all
done
echo "Your dev environment resources under namespace ${DEV_NAMESPACE} have been deleted"
echo

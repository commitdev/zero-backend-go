#!/bin/bash

# This script runs only when billingEnabled = "yes", invoked from makefile
# modify the kubernetes application secret and appends STRIPE_API_SECRET_KEY
# the deployment by default will pick up all key-value pairs as env-vars from the secret

if [[ "$ENVIRONMENT" == "" ]]; then
  echo "Must specify \$ENVIRONMENT to create stripe secret ">&2; exit 1;
elif [[ "$ENVIRONMENT" == "stage" ]]; then
PUBLISHABLE_API_KEY=$stagingStripePublicApiKey
SECRET_API_KEY=$stagingStripeSecretApiKey
elif [[ "$ENVIRONMENT" == "prod" ]]; then
PUBLISHABLE_API_KEY=$productionStripePublicApiKey
SECRET_API_KEY=$productionStripeSecretApiKey
fi

CLUSTER_NAME=${PROJECT_NAME}-${ENVIRONMENT}-${REGION}
NAMESPACE=${PROJECT_NAME}

BASE64_TOKEN=$(printf ${SECRET_API_KEY} | base64)
## Modify existing application secret to have stripe api key
kubectl --context $CLUSTER_NAME -n $NAMESPACE get secret ${PROJECT_NAME} -o json | \
  jq --arg STRIPE_API_SECRET_KEY $BASE64_TOKEN '.data["STRIPE_API_SECRET_KEY"]=$STRIPE_API_SECRET_KEY' \
  | kubectl apply -f -

sh ${PROJECT_DIR}/scripts/stripe-example-setup.sh

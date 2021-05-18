#!/bin/bash

# This script runs only when billingEnabled = "yes", invoked from makefile
# It will modify the application secret in Secrets Manager and append STRIPE_API_SECRET_KEY
# This will be synced to k8s and the deployment will pick up all key-value pairs as env vars from the secret

if [[ "$ENVIRONMENT" == "stage" ]]; then
  PUBLISHABLE_API_KEY=$stagingStripePublicApiKey
  SECRET_API_KEY=$stagingStripeSecretApiKey
elif [[ "$ENVIRONMENT" == "prod" ]]; then
  PUBLISHABLE_API_KEY=$productionStripePublicApiKey
  SECRET_API_KEY=$productionStripeSecretApiKey
else
  echo 'Must specify $ENVIRONMENT (stage/prod) to create stripe secret'>&2; exit 1;
fi

SECRET_NAME=${PROJECT_NAME}/kubernetes/${ENVIRONMENT}/${PROJECT_NAME}
BASE64_TOKEN=$(printf ${SECRET_API_KEY} | base64)

# Modify existing application secret to add stripe api key
UPDATED_SECRET=$(aws secretsmanager get-secret-value --region ${REGION} --secret=${SECRET_NAME} --query "SecretString" --output text | \
  jq --arg STRIPE_API_SECRET_KEY ${BASE64_TOKEN} '.STRIPE_API_SECRET_KEY=$STRIPE_API_SECRET_KEY')
aws secretsmanager update-secret --secret-id=${SECRET_NAME} --secret-string="${UPDATED_SECRET}"

sh ${PROJECT_DIR}/scripts/stripe-example-setup.sh

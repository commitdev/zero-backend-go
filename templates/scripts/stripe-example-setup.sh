#!/bin/bash
set -e

# Creates stripe example for frontend/backend for checkout and subscription
# the script uses the token and creates the following for the end-to-end example to work
# - 1 product
# - 3 plans
# - 1 webhook
#
# If you want to recreate this you can use the curl requests as an example below.

PROJECT_NAME=<% .Name %>
RANDOM_SEED=<% index .Params `randomSeed` %>
REGION=<% index .Params `region` %>

echo "Running on ${ENVIRONMENT}"
if [[ "$ENVIRONMENT" == "" ]]; then
  exit 1;
elif [[ "$ENVIRONMENT" == "stage" ]]; then
BACKEND_API_WEBHOOK_ENDPOINT="https://<% index .Params `stagingBackendSubdomain` %><% index .Params `stagingHostRoot` %>/webhook/stripe"
PUBLISHABLE_API_KEY=$stagingStripePublicApiKey
SECRET_API_KEY=$stagingStripeSecretApiKey
elif [[ "$ENVIRONMENT" == "prod" ]]; then
BACKEND_API_WEBHOOK_ENDPOINT="https://<% index .Params `productionBackendSubdomain` %><% index .Params `productionHostRoot` %>/webhook/stripe"
PUBLISHABLE_API_KEY=$productionStripePublicApiKey
SECRET_API_KEY=$productionStripeSecretApiKey
fi

TOKEN=$(echo $SECRET_API_KEY | base64)
AUTH_HEADER="Authorization: Basic ${TOKEN}"

## Create Product
PRODUCT_ID=$(curl -XPOST \
  --url https://api.stripe.com/v1/products \
  --header "${AUTH_HEADER}" \
  -d "name"="$PROJECT_NAME" | jq -r ".id")

curl https://api.stripe.com/v1/prices \
  --header "${AUTH_HEADER}" \
  -d "product"="$PRODUCT_ID" \
  -d "unit_amount"=5499 \
  -d "currency"="CAD" \
  -d "recurring[interval]=month" \
  -d "nickname"="Monthly Plan"

curl https://api.stripe.com/v1/prices \
  --header "${AUTH_HEADER}" \
  -d "product"="$PRODUCT_ID" \
  -d "unit_amount"=299 \
  -d "currency"="CAD" \
  -d "recurring[interval]=day" \
  -d "nickname"="Daily Plan"

  curl https://api.stripe.com/v1/prices \
  --header "${AUTH_HEADER}" \
  -d "product"="$PRODUCT_ID" \
  -d "unit_amount"=50000 \
  -d "currency"="CAD" \
  -d "recurring[interval]=year" \
  -d "nickname"="Annual Plan"

# Create webhook on stripe platform
# See link for available webhooks: https://stripe.com/docs/api/webhook_endpoints/create?lang=curl#create_webhook_endpoint-enabled_events
curl https://api.stripe.com/v1/webhook_endpoints \
  --header "${AUTH_HEADER}" \
  -d url="${BACKEND_API_WEBHOOK_ENDPOINT}" \
  -d "enabled_events[]"="charge.failed" \
  -d "enabled_events[]"="charge.succeeded" \
  -d "enabled_events[]"="customer.created"  \
  -d "enabled_events[]"="subscription_schedule.created"

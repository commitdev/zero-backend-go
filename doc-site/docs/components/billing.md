---
title: Billing using Stripe
sidebar_label: Stripe
sidebar_position: 3
---

## Billing example
If you have enabled Billing from Zero, a subscription and checkout example using [Stripe](https://stripe.com), coupled with the backend repository to provide an end-to-end checkout example for you to customize. We also setup a webhook and an endpoint in the backend to receive webhook when events occur.

### Requirements
This billing example requires the following backend API endpoints:
```
GET /billing/products
POST /billing/success
POST /billing/cancel
POST /billing/checkout
```

### Initialization
`zero apply` will run a script adding your Stripe API keys to external secret, allowing your kubernetes deployment to access it.


### Setup
The following example content has been set up in Stripe:
- 1 product
- 3 prices(subscriptions) [annual, monthly, daily]
- 1 webhook [`charge.failed`, `charge.succeeded`, `customer.created`, `subscription_schedule.created`]
See link for available webhooks: https://stripe.com/docs/api/webhook_endpoints/create?lang=curl#create_webhook_endpoint-enabled_events

this is setup using the script [scripts/stripe-example-setup.sh][backend-stripe-setup-script]

### Deployment
The initialization step already added your Stripe API key to AWS secret manager hooked up with External Secrets, if you need to update the API Key you can simply edit the value in AWS Secret Manager (this will mean you have to update the frontend publishable key as well)

[backend-stripe-setup-script]: https://github.com/commitdev/zero-deployable-backend/blob/main/templates/scripts/stripe-example-setup.sh
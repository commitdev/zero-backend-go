#  <% .Name %> Backend service

# Getting started
You now have a repo to start writing your backend logic! The Go api comes with an endpoint returning the status of the app.

# Deployment
## Kubernetes
Your application is deployed on your EKS cluster through circleCI, you can see the pod status on kubernetes in your application namespace:
```
kubectl -n <% .Name %> get pods
```
### Configuring
You can update the resource limits in the [kubernetes/base/deployment.yml][base-deployment], and control fine-grain customizations based on environment and specific deployments such as Scaling out your production replicas from the [overlays configurations][env-prod]

## Circle CI
Your repository comes with a end-to-end CI/CD pipeline, which includes the following steps:
1. Checkout
2. Unit Tests
3. Build and Push Image
4. Deploy Staging
5. Integration Tests
6. Deploy Production


[See details on CircleCi][circleci-details]

## Database credentials
Your application is assumed[(ref)][base-deployment-secret] to rely on a database(RDS), In your Kubernetes
application namespace, an application specific user has been created for you and hooked up to the application already.

## Cron Jobs
An example cron job is specified in [kubernetes/base/cronjob.yml][base-cronjob].
The default configuration specifies `suspend: true` to ensure this cronjob does not run unless you want to enable it.
When you are ready for your cron job to run, make sure to set `suspend: false`.

The default cron job specifies three parameters that you will need to change depending on your application's needs:

### Schedule
See a detailed specification of the [cron schedule format](https://en.wikipedia.org/wiki/Cron#Overview).
This will need to be modified to fit the constraints of your application.

### Image
The default image specified is a barebones busybox base image.
You likely want to run processes dependent on your backend codebase; so the image will likely be the same as for your backend application.

### Args
As per the image attribute noted above, you will likely be running custom arguments in the context of that image.
You should specify those arguments [as per the documentation](https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/).

<!-- Links -->
[base-cronjob]: ./kubernetes/base/cronjob.yml
[base-deployment]: ./kubernetes/base/deployment.yml
[base-deployment-secret]: ./kubernetes/base/deployment.yml#L49-58
[env-prod]: ./kubernetes/overlays/production/deployment.yml
[circleci-details]: ./.circleci/README.md

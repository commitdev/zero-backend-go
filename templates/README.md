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
Your application is assumed[(ref)][base-deployment-secret] to rely on a database(RDS), I
n your Kubernetes application namespace, an application specific user has been created for you and hooked up to the application already. 

<!-- Links -->
[base-deployment]: ./kubernetes/base/deployment.yml
[base-deployment-secret]: ./kubernetes/base/deployment.yml#L49-58
[env-prod]: ./kubernetes/overlays/production/deployment.yml
[circleci-details]: ./.circleci/README.md

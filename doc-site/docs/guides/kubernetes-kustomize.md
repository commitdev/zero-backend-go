---
title: Kubernetes & Kustomize
sidebar_label: Kubernetes & Kustomize
sidebar_position: 1
---

## Application
Your application is deployed on your EKS cluster through circleCI, you can see the pod status on kubernetes in your application namespace:
```
kubectl -n <APP_NAME> get pods
```
## Configuring
You can update the resource limits in the [kubernetes/base/deployment.yml][base-deployment], and control fine-grain customizations based on environment and specific deployments such as Scaling out your production replicas from the [overlays configurations][env-prod]


[base-cronjob]: https://github.com/commitdev/zero-deployable-node-backend/tree/main/templates/kubernetes/base/cronjob.yml
[base-deployment]: https://github.com/commitdev/zero-deployable-node-backend/tree/main/templates/kubernetes/base/deployment.yml
[env-prod]: https://github.com/commitdev/zero-deployable-node-backend/tree/main/templates/kubernetes/overlays/production/deployment.yml
[circleci-details]: https://github.com/commitdev/zero-deployable-node-backend/tree/main/templates/.circleci/README.md
# Zero Deployable Backend
This is a [Zero][zero] module which sets up a
service which can be deployed to the environment set up with [zero-aws-eks-stack][zero-infra].

The `/templates` folder is meant to be filled in via [Zero][zero] and results in Simple Go Service with a status endpoint. It also contains a simple CircleCI pipeline which defines how to build and deploy the service.

This repository is language/business-logic agnostic; mainly showcasing some universal best practices:
- Built in containerization with docker
- Deployment flow with kubernetes
- Out of the box CI/CD flow CircleCi
  - testing
  - building docker image
  - uploading docker image to private registry (ECR)
  - deploy with kustomize
  - manual approval step for production environment


## Repository structure
```sh
/   # file in the root directory is for initializing the user's repo and declaring metadata
|-- Makefile                        #make command triggers the initialization of repository
|-- zero-module.yml                 #module declares required parameters and credentials
|   # files in templates become the repo for users
|   scripts/
|   |   # these are scripts called only once during zero apply, and we don't
|   |   # expect a need to rerun them throughout development of the  repository
|   |   # used for checking binary requires / setting up CI / secrets
|   |   |-- check.sh
|   |   |-- gha-setup.sh
|   |   |-- required-bins.sh
|   |   |-- setup-stripe-secrets.sh
|   templates/
|   |   # this makefile is used both during init and
|   |   # on-going needs/utilities for user to maintain their infrastructure
|   |-- Makefile
|   |-- kubernetes/
|       |-- base/
|       |   |-- cronjob.yml
|       |   |-- deployment.yml
|       |   |-- kustomization.yml
|       |   |-- service.yml
|       |-- migration/
|       |   |-- job.yml
|       |-- overlays/
|       |   |-- production/
|       |   |   |-- deployment.yml
|       |   |   |-- ingress.yml
|       |   |   |-- kustomization.yml
|       |   |   |-- pdb.yml
|       |   |-- staging/
|       |   |   |-- deployment.yml
|       |   |   |-- ingress.yml
|       |   |   |-- kustomization.yml
|       |   |   |-- pdb.yml
|       |   |-- dev/
|       |   |   |-- deployment.yml
|       |   |   |-- ingress.yml
|       |   |   |-- kustomization.yml
|       |   |   |-- pdb.yml
|       |-- secrets/
|       |   |-- .gitignore
|       |   |-- kustomization.yml
|       |   |-- namespace.yml

```

**Prerequisites**
- Kubernetes Cluster up and running
- Have CircleCI and Github token setup with the Zero project
- CI-user created via EKS-stack with access to ECR and your EKS

## Initialization
This step is meant to be executed during `zero apply`, includes following steps:
- Adding environment variables to CircleCI project
- Linking the CircleCi with the github repository
  - Linking the circleCI will automatically trigger the first build and deploy your application to EKS cluster


### Frontend Repo

The corresponding frontend for this app is [zero-deployable-react-frontend][zero-frontend].

## Other links
Project board: [zenhub][zenhub-board]



<!-- Links -->
[zero]: https://github.com/commitdev/zero
[zero-infra]: https://github.com/commitdev/zero-aws-eks-stack
[zero-frontend]: https://github.com/commitdev/zero-deployable-react-frontend

[zenhub-board]: https://app.zenhub.com/workspaces/commit-zero-5da8decc7046a60001c6db44/board?filterLogic=any&repos=203630543,247773730,257676371,258369081

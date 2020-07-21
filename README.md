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
|   db-ops/
|   |-- create-db-user.sh
|   |-- job-create-db.yml.tpl
|   # files in templates become the repo for users
|   templates/
|   |   # this makefile is used both during init and
|   |   # on-going needs/utilities for user to maintain their infrastructure
|   |-- Makefile
|   |-- kubernetes/
|       |-- base/              
|       |   |-- deployment.yml
|       |   |-- kustomization.yml
|       |   |-- service.yml
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
- Creating the application database's credentials


### Application Database user creation
Using environment variables injected from Zero, it will fetch the RDS master password from AWS secret manager
- creates a namespace
- creates a job with a SQL query file mounted generating an application user
- creating a secret in the application namespace in your EKS cluster
- removing the RDS master password for security reasons

_Note: the user creation only happens once during `zero apply`, for details see the `make create-db-user` command_ 

### Frontend Repo

The corresponding frontend for this app is [zero-deployable-react-frontend][zero-frontend].

## Other links
Project board: [zenhub][zenhub-board]



<!-- Links -->
[zero]: https://github.com/commitdev/zero
[zero-infra]: https://github.com/commitdev/zero-aws-eks-stack
[zero-frontend]: https://github.com/commitdev/zero-deployable-react-frontend

[zenhub-board]: https://app.zenhub.com/workspaces/commit-zero-5da8decc7046a60001c6db44/board?filterLogic=any&repos=203630543,247773730,257676371,258369081
---
title: Module Life cycle
sidebar_label: Module Life cycle
sidebar_position: 4
---


## Prerequisites
The CI/CD pipeline of the module requires AWS EKS cluster to be available as the deployment destination, it setups a namespace / ingress / service / deployment during the pipeline.

## Scaffold
Based on Parameters in Project definition(`zero-project.yml`), module will be scaffolded and templated out during Zero create

Options that alter the templated repository
- `database`: whether to include `mysql`/`postgresql` database driver
- `userAuth`: Determines whether user auth provider is included in your repository
- `CIVendor`: Scaffolds one of CircleCI / Github actions deployment pipeline
- `billingEnabled`: Includes billing page to load products and api calls to communicated with backend service, and API key in `config.json`


## Module Initialize phase
_Run once only during `zero apply`_
- Sets up CI pipeline with `env-vars` and secrets containing CI-user's AWS Credentials
- Github Actions will rerun the initial commit since it was first ran without the credentials (during `zero create`)

## On-going
### Pull request
- Unit test
### Push to master branch
- Unit test
- Build docker image
- Deploy image to Staging cluster using Kustomize
- Deploy image to Production cluster using Kustomize

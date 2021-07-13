---
title: Overview
sidebar_label: Overview
sidebar_position: 1
---

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


### Frontend Repo

The corresponding frontend for this app is [zero-deployable-react-frontend][zero-frontend].


<!-- Links -->
[zero]: https://github.com/commitdev/zero
[zero-infra]: https://github.com/commitdev/zero-aws-eks-stack
[zero-frontend]: https://github.com/commitdev/zero-deployable-react-frontend

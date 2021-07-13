---
title: Continuous Integration and Delivery
sidebar_label: CI/CD
sidebar_position: 2
---

## Circle CI
Your repository comes with a end-to-end CI/CD pipeline, which includes the following steps:
1. Checkout
2. Unit Tests
3. Build and Push Image
4. Deploy Staging
5. Integration Tests
6. Approval to Deploy to production
7. Deploy Production


[See details on CircleCi][circleci-details]

## Github actions
Your repository comes with a end-to-end CI/CD pipeline, which includes the following steps:
1. Checkout
2. Unit Tests
3. Build Image
4. Upload Image to ECR
4. Deploy image to Staging cluster
5. Integration tests
6. Deploy image to Production cluster

**Note**: you can add a approval step using Github Environments(Available for Public repos/Github pro), you can configure an environment in the Settings tab then simply add the follow to your ci manifest (`./.github/workflows/ci.yml`)
```yml
deploy-production: # or any step you would like to require Explicit approval
  enviroments:
    name: <env-name>
```
### Branch Protection
Your repository comes with a protected branch `master` and you can edit Branch protection in **Branches** tab of Github settings. This ensures code passes tests before getting merged into your default branch.
By default it requires `[lint, unit-test]` to be passing to allow Pull requests to merge.
<% end %>

[circleci-details]: https://github.com/commitdev/zero-deployable-node-backend/tree/main/templates/.circleci/README.md
[github-actions]: https://github.com/commitdev/zero-deployable-node-backend/tree/main/templates/.github/workflows/ci.yml
# CircleCI Pipeline Template

## Configuration

### Requirements

Requires you to configure the below [CircleCI Environment Variables](https://circleci.com/docs/2.0/env-vars/):
```yml
- AWS_ACCESS_KEY_ID         # AWS access key for the circleci user - this should be in AWS secret manager
- AWS_SECRET_ACCESS_KEY     # AWS secret for the circleci user - this should be in AWS secret manager
- CIRCLECI_API_KEY          # Needed for the queueing orb. You can generate this in the project settings in CircleCI. It needs the `status` scope.

- SLACK_WEBHOOK             # Webhook for slack notifications. Must only be specified if you uncomment `slack/notify-on-failure`
```

## Deployment Process

### Branch Deploys

1. [Checkout](#checkout)
2. [Unit Tests](#unit-tests)

### Master Deploys

1. [Checkout](#checkout)
2. [Unit Tests](unit-tests)
3. [Build and Push Image](#build-and-push-image)
4. [Deploy Staging](#deploy-staging)
5. [Integration Tests](#integration-test)
6. [Deploy Production](#deploy-production)

## Checkout

We checkout code in a separate step and then save to a shared workspace throughout the rest of the build. This is done to avoid needing to run the checkout in multiple steps throughout the build.

## Unit Tests

We run the tests inside a Go container. This runs parallel to the build process to save time. We run unit tests on branches before merging to master so these should never fail on the master branch. Results are piped into go-junit-reporter to allow CircleCI to parse them for [Insights](https://circleci.com/build-insights/gh/Vin65/shipping-service/master).

## Build and Push Image

Uses the ECR orb (See: [Orbs](#orbs)) to build the Dockerfile and push the image up to ECR.

## Deploy Staging

Still finishing up with this, currently it just runs the command `make deploy-staging`

## Integration Tests

Set of tests that need to run against a working version of the application. These are run after deploying to a staging or testing server.

## Deploy Production

This does the same EKS deployment, just waits for other builds to finish deploying first.

## Orbs

### AWS

- [ECR Orb](https://circleci.com/orbs/registry/orb/circleci/aws-ecr)
- [EKS Orb](https://circleci.com/orbs/registry/orb/circleci/aws-eks)
- [CLI Orb](https://circleci.com/orbs/registry/orb/circleci/aws-cli)

We use multiple AWS orbs to simplify the deployment process. Firstly to build the image and push to the repo, we use the `aws-ecr` orb. This just combines the commands needed to build a docker image, tag it, and push to ECR. The tags are dealt with by the `version-tag` orb (see below).

### Slack

- [Slack Orb](https://circleci.com/orbs/registry/orb/circleci/slack)

You'll need to set up a slack webhook to post messages to a channel in Slack. You can do it in the [Incoming Webhooks](https://winedirectteam.slack.com/apps/A0F7XDUAZ-incoming-webhooks?next_id=0) page. This is then added as an environment variable on your project with the name `SLACK_WEBHOOK` as per the [Slack Orb Documentation](https://circleci.com/orbs/registry/orb/circleci/slack).

### Commit Version Tag

- [Version Tag Orb](https://circleci.com/orbs/registry/orb/commitdev/version-tag)

This is a custom orb used by (Commit)[https://commit.dev] to create a tag for docker images that is easier to work with. Instead of using the full Git SHA
as the docker image tag, we use the build number from CircleCI and a short version of the Git SHA (first seven characters only). You'll find the tag for each build in the "Create Version Tag" step inside the `build_and_push` job.

E.g. `Created version tag: VERSION_TAG=164-27a3d39`

This is done to increase the readability, make the numbers sortable and still guarantee uniqueness with a high degree of certainty.

### Queue

- [EddieWebb Queue Orb](https://circleci.com/orbs/registry/orb/eddiewebb/queue)

This orb is used to prevent multiple deployments going out at the same time. By using the CIRCLECI_API_KEY to access the current running builds, it's able to check that the current build is the oldest in the queue, and therefore is able to run first. Other builds in the queue will be put into a wait/retry loop until all builds before them have finished.

This is run before the deploy production step to prevent two builds deploying to production at the same time.

```yaml
        - queue/block_workflow:
            time: '30' # hold for 30 mins then abort
            requires:
              - wait_for_approval
```

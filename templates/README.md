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

### Dev Environment
This project is set up with a local/cloud hybrid dev environment. This means you can do fast local development of a single service, even if that service depends on other resources in your cluster. 
Make a change to your service, run it, and you can immediately see the new service in action in a real environment. You can also use any tools like your local IDE, debugger, etc. to test/debug/edit/run your service.

Usually when developing you would run the service locally with a local database and any other dependencies running either locally or in containers using `docker-compose`, `minikube`, etc. 
Now your service will have access to any dependencies within a namespace running in the EKS cluster, with access to resources there.
[Telepresence](https://telepresence.io) is used to provide this functionality. 

 Development workflow:
 
  1. Run `start-dev-env.sh` - You will be dropped into a shell that is the same as your local machine, but works as if it were running inside a pod in your k8s cluster
  2. Change code and run the server - As you run your local server, using local code, it will have access to remote dependencies, and will be sent traffic by the load balancer
  3. Test on your cloud environment with real dependencies - `https://<your name>-<% index .Params `stagingBackendSubdomain` %><% index .Params `stagingHostRoot` %>`
  4. git commit & auto-deploy to Staging through the build pipeline


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

# APIs Specification
## File Upload
```
GET /file/presigned?bucket=bucketname&key=filepath&action=upload
```
### Parameters
Parameter | Description 
--- | --- 
bucket | The bucket name on S3
key | The path+filename on the Bucket
action | The action of upload or download

### Request Example
```
curl --location --request GET 'http://localhost:8090/file/presigned?bucket=bigfile-bucket&key=hello.txt&action=upload'
```
### Response Body
Properties | Description 
--- | --- 
url | The presigned url of uploading a file
method | The method of request to upload the file

### Response Body Example
```
{
    "url": "https://bigfile-bucket.s3.us-west-2.amazonaws.com/hello.txt?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIIJ25ZBTRCYZHE4A%2F20201215%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20201215T180519Z&X-Amz-Expires=3600&X-Amz-SignedHeaders=host&X-Amz-Signature=981aa47912512e7816b2e22ca70d8d541220dea549cb2f12f34006f6adf31af4",
    "method": "PUT"
}
```

## File Download
```
GET /file/presigned?bucket=bucketname&key=filepath
```
### Parameters
Parameter | Description 
--- | --- 
bucket | The bucket name on S3
key | The path+filename on the Bucket

### Request Example
```
curl --location --request GET 'http://localhost:8090/file/presigned?bucket=bigfile-bucket&key=hello.txt'
```
### Response Body
Properties | Description 
--- | --- 
url | The presigned url of uploading a file
method | The method of request to upload the file

### Response Body Example
```
{
    "url": "https://bigfile-bucket.s3.us-west-2.amazonaws.com/hello.txt?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIIJ25ZBTRCYZHE4A%2F20201215%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20201215T180519Z&X-Amz-Expires=3600&X-Amz-SignedHeaders=host&X-Amz-Signature=981aa47912512e7816b2e22ca70d8d541220dea549cb2f12f34006f6adf31af4",
    "method": "GET"
}
```



<!-- Links -->
[base-cronjob]: ./kubernetes/base/cronjob.yml
[base-deployment]: ./kubernetes/base/deployment.yml
[base-deployment-secret]: ./kubernetes/base/deployment.yml#L49-58
[env-prod]: ./kubernetes/overlays/production/deployment.yml
[circleci-details]: ./.circleci/README.md

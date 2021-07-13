---
title: Cloudfront Signed URLs
sidebar_label: Cloudfront Signed URLs
sidebar_position: 5
---

## Overview
Cloudfront Signed URL allows you to control the access to your content through policies . So you can securely distribute content with the access control you set. Letting you set things like expiry date on the URL without having to modify the origin content.

## Requirements
To use Signed URLs on cloudfront you will have to follow the [AWS documentation to creating a key-pair][creating-key-pairs] which requires having root permission to your AWS account.

## Environment Settings
Before you get presigned url from S3, make sure the following environment variables have been set.

Variable | Description
--- | ---
AWS_ACCESS_KEY_ID | The IMA user's access key id with full control permission to S3
AWS_Secret_Access_Key | The IMA user's secret access key
AWS_REGION | The AWS region, such as "us-east-1", "us-west-2"
AWS_S3_DEFAULT_BUCKET | optional, default bucket is applied if the bucket name isn't assigned by user

## Get presigned url for upload
```shell
curl --request GET 'http://localhost:8090/file/presigned?key=filepath[&bucket=bucketname]'
```
Note: The path variable :key doesn't allow the value is a path which includes '/' so that we change it from path variable to a query string
### Parameters
Parameter | Description
--- | ---
key | The path+filename on the Bucket
bucket | The bucket name on S3. The default value will be applied if it isn't given.


### Request Example
```shell
curl --location --request GET 'http://localhost:8090/file/presigned?key=images/windows.png'
```
```shell
curl --location --request GET 'http://localhost:8090/file/presigned/key=images/windows.png&bucket=bigfile-bucket'
```
### Response Body
Properties | Description
--- | ---
url | The presigned url of uploading a file
method | The method of request to upload the file

### Response Body Example
```shell
{
    "url": "https://bigfile-bucket.s3.us-west-2.amazonaws.com/images/windows.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AK%2F20201215%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20201215T180519Z&X-Amz-Expires=3600&X-Amz-SignedHeaders=host&X-Amz-Signature=1234",
    "method": "PUT"
}
```
### How to use this presigned url to upload
#### Syntax
```shell
curl --location --request PUT '[presigned url for update]' --header 'Content-Type: [type]' --data-binary '[Absolute Path on local]'
```
#### Example
```shell
curl --location --request PUT 'https://bigfile-bucket.s3.us-west-2.amazonaws.com/images/windows.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AK%2F20201215%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20201215T180519Z&X-Amz-Expires=3600&X-Amz-SignedHeaders=host&X-Amz-Signature=1234' \
--header 'Content-Type: text/plain' \
--data-binary '/user/work/hello.txt'
```


## Get presigned url for download
```shell
curl --request GET 'http://localhost:8090/file?key=filepath[&bucket=bucketname]'
```

### Parameters
Parameter | Description
--- | ---
key | The path+filename on the Bucket
bucket | Optional, The bucket name on S3. The default value will be applied if it isn't given.

### Request Example
```shell
curl --location --request GET 'http://localhost:8090/file?key=images/windows.png'
```

```shell
curl --location --request GET 'http://localhost:8090/file?key=images/windows.png&bucket=bigfile-bucket'bucket=bigfile-bucket'
```

### Response Body

Properties | Description
--- | ---
url | The presigned url of uploading a file
method | The method of request to upload the file

### Response Body Example
```
{
    "url": "https://bigfile-bucket.s3.us-west-2.amazonaws.com/images/windows.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AK%2F20201215%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20201215T180519Z&X-Amz-Expires=3600&X-Amz-SignedHeaders=host&X-Amz-Signature=1234",
    "method": "GET"
}
```

### How to use this presigned url to download
#### download through browser
Copy this presigned url and paste it into your browser, then done.
#### download through curl
```shell
curl --location --request GET '[presigned url for download]'
```


[creating-key-pairs]: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-trusted-signers.html#private-content-creating-cloudfront-key-pairs
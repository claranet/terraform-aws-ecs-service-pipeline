# terraform-aws-ecs-pipeline

These modules are used to create ECS services and CodePipeline pipelines for deploying images to them. It uses a **rolling update** deployment strategy.

## Overview

* ECS services are created using CloudFormation with a [rolling update ECS deployment controller](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-type-ecs.html).
* Optional approval step per environment (e.g. automatically deploy to dev, but wait for approval before deploying production).
* Supports cross-account pipelines.

The following diagram shows how we have used this module to handle image deployments to ECS services in multiple environments. Deployments always roll out to the development environment straight away, but require approval before being promoted to the staging and production environments.

![Diagram](diagram.png?raw=true)

## Service module

The `service` module creates an ECS service using CloudFormation. Don't worry, it's still managed by Terraform  in the same way as other AWS resources. CodePipeline natively supports performing CloudFormation stack updates, so this is the ideal way to manage the service and its related resources.

This module outputs a `pipeline_target` value to be passed into the `pipeline` module.

## ECR source module

The `ecr-source` module creates an ECR repository and an IAM user which has permission to upload image to that repository.

This module outputs a `location` value to be passed into the `pipeline` module. It also outputs a `creds` value containing AWS credentials, to be used by external build systems to upload deployable artifacts.

Using this module is optional. It is just a quick and easy way to create an ECR repository and credentials.

## Pipeline module

The `pipeline` module creates a CodePipeline pipeline for image deployment.

The pipeline will update the ECS service CloudFormation stacks to use the image. Tasks in the service will be replaced with new tasks using the new image.

## Putting it all together

1. Use the `service` module in one or more environments.
2. Use the `ecr-source` module to create an ECR repository, with IAM credentials, which will be used to trigger a pipeline when images are pushed.
3. Use the `pipeline` module to create pipeline(s).
    * Pass in the `location` output from the `ecr-source` module.
    * Pass in the `pipeline_target` output from anywhere you used the `service` module.
4. Push an image to ECR to trigger the pipeline.

## Caveats

### CodePipeline is what it is

This uses CodePipeline, which comes with some limitations and quirks:

* The pipeline is linear, going from one environment to the next. You cannot choose to deploy to a specific environment; you must promote it all the way through the predefined pipeline.
* It is confusing when there are multiple pipeline executions running at the same time. The CodePipeline console can be deceptive, for example making it look like you are approving the version currently running in staging into production, but you may actually be approving the previous version. Make sure to check the `Pipeline execution ID` and `Source` when approving deployments.

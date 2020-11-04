import json

import boto3
import cfnresponse

ecs_client = boto3.client("ecs")


def lambda_handler(event, context):
    status = cfnresponse.FAILED
    physical_resource_id = None
    response_data = {}
    try:

        # Avoids deletes?
        physical_resource_id = event.get("PhysicalResourceId")

        # Check if CloudFormation is deleting the resource.
        request_type = event["RequestType"]
        is_delete_operation = request_type == "Delete"

        # Check if the pipeline has been used yet.
        image = event["ResourceProperties"]["Image"]
        is_new_pipeline = image == "-"

        if is_delete_operation or is_new_pipeline:

            if is_delete_operation:
                print("Delete operation, set to 0")
            elif is_new_pipeline:
                print("New pipeline, set to 0")

            desired_count = 0
            log_stream_prefix = "disabled"
            max_capacity = 0
            min_capacity = 0

        else:

            desired_count = get_ecs_service_desired_count(
                cluster_name=event["ResourceProperties"]["ClusterName"],
                service_name=event["ResourceProperties"]["ServiceName"],
            )

            if ":" in image:
                log_stream_prefix = image.split(":")[-1]
            else:
                log_stream_prefix = image.split("/")[-1]

            max_capacity = int(event["ResourceProperties"]["MaxCapacity"])
            min_capacity = int(event["ResourceProperties"]["MinCapacity"])

            desired_count = min(max(desired_count, min_capacity), max_capacity)

        response_data = {
            "DESIRED_COUNT": desired_count,
            "IMAGE": image,
            "LOG_STREAM_PREFIX": log_stream_prefix,
            "MAX_CAPACITY": max_capacity,
            "MIN_CAPACITY": min_capacity,
        }

        print(json.dumps(response_data))

        status = cfnresponse.SUCCESS

    finally:
        cfnresponse.send(event, context, status, response_data, physical_resource_id)


def get_ecs_service_desired_count(cluster_name, service_name):
    response = ecs_client.describe_services(
        cluster=cluster_name,
        services=[service_name],
    )
    for service in response["services"]:
        return service["desiredCount"]
    raise Exception(
        f"desiredCount not found for cluster: {cluster_name} service: {service_name}"
    )

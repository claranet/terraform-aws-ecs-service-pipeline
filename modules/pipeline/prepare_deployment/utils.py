import json
import tempfile
import zipfile
from contextlib import contextmanager
from functools import wraps
from traceback import TracebackException

import boto3

codepipeline_client = boto3.client("codepipeline")
ec2_client = boto3.client("ec2")
sts_client = boto3.client("sts")


def codepipeline_lambda_handler(func):
    """
    Decorates a lambda handler function to set up logging and error handling.
    Sends a failure result to CodePipeline if the decorated function raises
    an exception, otherwise sending a success result.

    """

    @wraps(func)
    def wrapped(event, context):

        # Set up logging and log the event.
        # Example event: https://docs.amazonaws.cn/en_us/lambda/latest/dg/services-codepipeline.html
        log.context = {"RequestId": context.aws_request_id}
        log("EVENT", json.dumps(event, indent=2))

        # Get the job data.
        job = event["CodePipeline.job"]

        # Process the job and then notify CodePipeline of its success or failure.
        try:
            func(event, context)
            log("SUCCESS")
            codepipeline_client.put_job_success_result(jobId=job["id"])
        except Exception as error:
            log("FAILURE", exception=error)
            codepipeline_client.put_job_failure_result(
                jobId=job["id"],
                failureDetails={
                    "type": "JobFailed",
                    "message": f"{error.__class__.__name__}: {error}",
                    "externalExecutionId": context.aws_request_id,
                },
            )

    return wrapped


@contextmanager
def create_zip_file(files):
    """
    Creates a temporary zip file on disk. The files parameter must be a
    dictionary of {filename: contents} which will be written to the zip
    file. The zip file path is yielded as the context value.

    """

    with tempfile.NamedTemporaryFile() as temp_file:
        with zipfile.ZipFile(temp_file.name, "w") as zip_file:
            for filename, contents in files.items():
                zip_file.writestr(filename, contents)
        yield temp_file.name


def get_artifact_s3_client(job):
    """
    Returns an S3 client with access to the CodePipeline artifact S3 bucket.

    """

    creds = job["data"]["artifactCredentials"]
    session = boto3.Session(
        aws_access_key_id=creds["accessKeyId"],
        aws_secret_access_key=creds["secretAccessKey"],
        aws_session_token=creds["sessionToken"],
    )
    return session.client("s3")


def get_cloudformation_template(cfn_client, stack_name):
    """
    Returns the template body of a CloudFormation stack.

    """

    response = cfn_client.get_template(StackName=stack_name)
    return response["TemplateBody"]


def get_input_artifact_location(job):
    """
    Returns the S3 location of the input artifact.

    """

    input_artifact = job["data"]["inputArtifacts"][0]
    input_location = input_artifact["location"]["s3Location"]
    input_bucket = input_location["bucketName"]
    input_key = input_location["objectKey"]
    return (input_bucket, input_key)


def get_output_artifact_location(job):
    """
    Returns the expected S3 destination location of the output artifact.
    The Lambda function needs to place an output artifact there.

    """

    output_artifact = job["data"]["outputArtifacts"][0]
    output_location = output_artifact["location"]["s3Location"]
    output_bucket = output_location["bucketName"]
    output_key = output_location["objectKey"]
    return (output_bucket, output_key)


def get_session(role_arn, session_name, duration_seconds=900):
    """
    Returns a boto3 session for the specified role.

    """

    response = sts_client.assume_role(
        RoleArn=role_arn,
        RoleSessionName=session_name,
        DurationSeconds=duration_seconds,
    )
    creds = response["Credentials"]
    return boto3.Session(
        aws_access_key_id=creds["AccessKeyId"],
        aws_secret_access_key=creds["SecretAccessKey"],
        aws_session_token=creds["SessionToken"],
    )


def get_user_parameters(job):
    """
    Returns the user parameters that were defined in CodePipeline.

    """

    return json.loads(
        job["data"]["actionConfiguration"]["configuration"]["UserParameters"]
    )


def log(title, message="", exception=None):
    """
    Logs a message, which will show up in CloudWatch Logs.

    """

    parts = [str(title)]
    for key, value in log.context.items():
        parts.append(key)
        parts.append(value)
    if message != "":
        parts.append(str(message))
    value = " ".join(parts)
    if exception:
        value += "\n"
        value += "\n".join(TracebackException.from_exception(exception).format())
    print(value.replace("\n", "\r"))


log.context = {}

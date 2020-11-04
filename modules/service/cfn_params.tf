# Create a CloudFormation custom resource Lambda function
# to return dynamic parameter values.

module "cfn_params_lambda" {
  source  = "raymondbutcher/lambda-builder/aws"
  version = "1.1.0"

  function_name = "${var.stack_name}-cfn-params"
  handler       = "lambda.lambda_handler"
  runtime       = "python3.7"
  memory_size   = 128
  timeout       = 30

  build_mode = "FILENAME"
  source_dir = "${path.module}/cfn_params"
  filename   = "${path.module}/cfn_params.zip"

  role_cloudwatch_logs       = true
  role_custom_policies       = [data.aws_iam_policy_document.cfn_params_lambda.json]
  role_custom_policies_count = 1
}

data "aws_iam_policy_document" "cfn_params_lambda" {
  statement {
    effect    = "Allow"
    actions   = ["ecs:DescribeServices"]
    resources = ["*"]
  }
}

module "prepare_deployment_lambda" {
  source  = "raymondbutcher/lambda-builder/aws"
  version = "1.1.0"

  function_name = "${var.name}-prepare-deployment"
  handler       = "lambda.lambda_handler"
  runtime       = "python3.6"
  filename      = ".terraform/prepare_deployment.zip"
  timeout       = 30

  # Enable build functionality.
  build_mode = "FILENAME"
  source_dir = "${path.module}/prepare_deployment"

  # Create and use a role with CloudWatch Logs permissions,
  # and attach a custom policy.
  role_cloudwatch_logs       = true
  role_custom_policies       = [data.aws_iam_policy_document.prepare_deployment_lambda.json]
  role_custom_policies_count = 1
}

data "aws_iam_policy_document" "prepare_deployment_lambda" {
  statement {
    sid       = "AssumeRoleInTargetAccounts"
    actions   = ["sts:AssumeRole"]
    resources = [for target in var.targets : target.assume_role.arn]
  }

  statement {
    sid       = "CodePipeline"
    effect    = "Allow"
    actions   = ["codepipeline:PutJobFailureResult", "codepipeline:PutJobSuccessResult"]
    resources = ["*"]
  }
}

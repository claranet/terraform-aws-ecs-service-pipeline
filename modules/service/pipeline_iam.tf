# This IAM role will be used by CodePipeline pipelines
# and associated Lambda functions in the pipeline account.

data "aws_iam_policy_document" "pipeline_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [var.pipeline_aws_account_id]
    }
  }
}

data "aws_iam_policy_document" "pipeline" {
  statement {
    sid       = "ArtifactBucket"
    actions   = ["s3:GetObject*"]
    resources = ["arn:${data.aws_partition.current.partition}:s3:::*-pipeline-${var.pipeline_aws_account_id}/*"]
  }

  statement {
    sid       = "ArtifactKMS"
    actions   = ["kms:Decrypt"]
    resources = ["arn:${data.aws_partition.current.partition}:kms:${data.aws_region.current.name}:${var.pipeline_aws_account_id}:key/*"]
  }

  statement {
    sid = "CloudFormation"
    actions = [
      "cloudformation:DescribeStacks",
      "cloudformation:GetTemplate",
      "cloudformation:UpdateStack",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:cloudformation:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stack/${var.stack_name}/*"]
  }

  statement {
    sid       = "IAM"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.cloudformation.arn]
  }

  statement {
    sid       = "ParameterStore"
    actions   = ["ssm:PutParameter"]
    resources = [aws_ssm_parameter.image.arn]
  }
}

resource "aws_iam_role" "pipeline" {
  name               = "${var.stack_name}-pipeline"
  assume_role_policy = data.aws_iam_policy_document.pipeline_assume_role.json
}

resource "aws_iam_role_policy" "pipeline" {
  role   = aws_iam_role.pipeline.name
  policy = data.aws_iam_policy_document.pipeline.json
}

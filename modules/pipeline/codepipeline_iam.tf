data "aws_iam_policy_document" "codepipeline_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codepipeline" {
  name               = "${var.name}-codepipeline"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume_role.json
}

data "aws_iam_policy_document" "codepipeline" {
  statement {
    sid = "ArtifactBucket"

    actions = [
      "s3:GetObject*",
      "s3:GetBucket*",
      "s3:List*",
      "s3:DeleteObject*",
      "s3:PutObject*",
      "s3:Abort*"
    ]

    resources = [
      aws_s3_bucket.pipeline.arn,
      "${aws_s3_bucket.pipeline.arn}/*"
    ]
  }

  statement {
    sid = "ArtifactKMS"

    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey",
    ]

    resources = [
      var.kms_key_arn,
    ]
  }

  statement {
    sid       = "AssumeRoleInTargetAccounts"
    actions   = ["sts:AssumeRole"]
    resources = [for target in var.targets : target.assume_role.arn]
  }

  statement {
    sid = "LambdaFunction"

    actions = [
      "lambda:InvokeFunction",
    ]

    resources = [
      module.prepare_deployment_lambda.arn,
    ]
  }

  statement {
    sid = "SourceRepository"

    actions = [
      "ecr:DescribeImages",
    ]

    resources = [
      var.source_location.repository_arn,
    ]
  }
}

resource "aws_iam_role_policy" "codepipeline" {
  role   = aws_iam_role.codepipeline.name
  policy = data.aws_iam_policy_document.codepipeline.json
}

# CodePipeline will try to use the IAM role straight away,
# but the policy needs to be attached first, which is
# eventually consistent, so introduce a delay here.

resource "time_sleep" "codepipeline_iam_role" {
  create_duration = "15s"
  triggers = {
    arn         = aws_iam_role.codepipeline.arn
    name        = aws_iam_role_policy.codepipeline.role         # depend on the policy attachment
    policy_hash = sha1(aws_iam_role_policy.codepipeline.policy) # depend on the policy content
  }
}

locals {
  codepipeline_role_arn = time_sleep.codepipeline_iam_role.triggers["arn"]
}

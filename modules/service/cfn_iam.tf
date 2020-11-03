data "aws_iam_role" "autoscaling" {
  name = "AWSServiceRoleForApplicationAutoScaling_ECSService"
}

data "aws_iam_policy_document" "cloudformation_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["cloudformation.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "cloudformation" {
  # Allow reading the input parameter from SSM.

  statement {
    sid       = "ReadParameters"
    actions   = ["ssm:GetParameters"]
    resources = [aws_ssm_parameter.image.arn]
  }

  # Allow invoking the parameters function.

  statement {
    sid       = "InvokeLambda"
    actions   = ["lambda:Invoke*"]
    resources = [module.cfn_params_lambda.arn]
  }

  # Allow managing ECS resources.

  statement {
    sid = "ManageEcs"
    actions = [
      "ecs:CreateService",
      "ecs:RegisterTaskDefinition",
      "ecs:DeregisterTaskDefinition",
      "ecs:*", # TODO: make strict
    ]
    resources = ["*"] # TODO: make strict
  }

  # Allow managing auto scaling resources.

  statement {
    sid = "ManageAutoScaling"
    actions = [
      "application-autoscaling:*", # TODO: make strict
    ]
    resources = ["*"] # TODO: make strict
  }

  # Allow use of these IAM roles.

  statement {
    sid     = "PassRole"
    actions = ["iam:PassRole"]
    resources = [
      aws_iam_role.ecs_execution.arn,
      aws_iam_role.ecs_task.arn,
      data.aws_iam_role.autoscaling.arn,
    ]
  }
}

resource "aws_iam_role" "cloudformation" {
  name               = "${var.stack_name}-cfn"
  assume_role_policy = data.aws_iam_policy_document.cloudformation_assume_role.json
}

resource "aws_iam_role_policy" "cloudformation" {
  role   = aws_iam_role.cloudformation.name
  policy = data.aws_iam_policy_document.cloudformation.json
}

# CloudFormation will try to use the IAM role straight away,
# but the policy needs to be attached first, which is
# eventually consistent, so introduce a delay here.

resource "time_sleep" "cloudformation_iam_role" {
  create_duration = "15s"
  triggers = {
    arn         = aws_iam_role.cloudformation.arn
    name        = aws_iam_role_policy.cloudformation.role         # depend on the policy attachment
    policy_hash = sha1(aws_iam_role_policy.cloudformation.policy) # depend on the policy content
  }
}

locals {
  cfn_role_arn = time_sleep.cloudformation_iam_role.triggers["arn"]
}

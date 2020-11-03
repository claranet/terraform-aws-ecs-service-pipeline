# We must create a role that can be assumed by CloudWatch Events to start an execution in our pipeline.
# https://docs.aws.amazon.com/codepipeline/latest/userguide/create-cwe-ecr-source-cfn.html

data "aws_iam_policy_document" "cloudwatch_events_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cloudwatch_events" {
  name               = "${var.name}-events"
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_events_assume_role.json
}

data "aws_iam_policy_document" "cloudwatch_events" {
  statement {
    actions   = ["codepipeline:StartPipelineExecution"]
    resources = [aws_codepipeline.this.arn]
  }
}

resource "aws_iam_role_policy" "cloudwatch_events" {
  role   = aws_iam_role.cloudwatch_events.name
  policy = data.aws_iam_policy_document.cloudwatch_events.json
}

resource "aws_cloudwatch_event_rule" "this" {
  name = var.name
  event_pattern = jsonencode({
    detail-type = ["ECR Image Action"]
    source      = ["aws.ecr"]
    detail = {
      action-type     = ["PUSH"]
      image-tag       = [var.source_location.image_tag]
      repository-name = [var.source_location.repository_name]
      result          = ["SUCCESS"]
    }
  })
}

resource "aws_cloudwatch_event_target" "this" {
  rule     = aws_cloudwatch_event_rule.this.name
  role_arn = aws_iam_role.cloudwatch_events.arn
  arn      = aws_codepipeline.this.arn
}

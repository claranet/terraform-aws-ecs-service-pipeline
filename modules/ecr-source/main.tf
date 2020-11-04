# ECR repositories.

resource "aws_ecr_repository" "this" {
  name = var.repo_name
}

resource "aws_ecr_repository" "extra" {
  for_each = toset(var.extra_repo_names)
  name     = each.value
}

data "aws_iam_policy_document" "ecr" {
  statement {
    sid = "AllowPull"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]
    principals {
      type        = "AWS"
      identifiers = [for each in var.pipeline_targets : each.execution_role.arn]
    }
  }
}

resource "aws_ecr_repository_policy" "this" {
  repository = aws_ecr_repository.this.name
  policy     = data.aws_iam_policy_document.ecr.json
}

resource "aws_ecr_repository_policy" "extra" {
  for_each   = toset(var.extra_repo_names)
  repository = aws_ecr_repository.extra[each.key].name
  policy     = data.aws_iam_policy_document.ecr.json
}

# IAM user.

resource "aws_iam_user" "this" {
  name = coalesce(var.user_name, aws_ecr_repository.this.name)
}

resource "aws_iam_access_key" "this" {
  user = aws_iam_user.this.name
}

data "aws_iam_policy_document" "user" {
  statement {
    sid       = "GetAuthorizationToken"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid = "AllowPush"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = concat(
      [aws_ecr_repository.this.arn],
      [for repo in aws_ecr_repository.extra : repo.arn],
    )
  }
}

resource "aws_iam_user_policy" "user" {
  user   = aws_iam_user.this.name
  name   = "ECR"
  policy = data.aws_iam_policy_document.user.json
}
